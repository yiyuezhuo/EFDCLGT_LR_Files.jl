using Base: with_logger
using Test
using EFDCLGT_LR_Files
using EFDCLGT_LR_Files: name

using Dates
using Logging
using TimeSeries

debug_logger = SimpleLogger(stdout, Logging.Debug)
default_logger = global_logger()
global_logger(debug_logger)

template = SimulationTemplate(ENV["WATER_ROOT"], Day, Hour, [qser_inp, wqpsc_inp, WQWCTS_OUT, cumu_struct_outflow_out])

@testset "EFDCLGT_LR_Files" begin
    @test name(efdc_inp) == "efdc.inp"

    replacer_base = Replacer(template, [efdc_inp, wqini_inp])
    replacer1 = copy(replacer_base)
    replacer2 = copy(replacer_base)

    set_sim_length!(replacer1, Day(1))
    set_sim_length!(replacer2, get_begin_day(DateTime, replacer_base) + Day(1))

    @test get_sim_length(DateTime, replacer1) == get_sim_length(DateTime, replacer2)
    @test get_sim_length(Day, replacer1) == get_sim_length(Day, replacer2)
    @test get_begin_day(DateTime, replacer1) == get_begin_day(DateTime, replacer2)
    @test get_begin_day(Day, replacer1) == get_begin_day(Day, replacer2)

    set_sim_length!(replacer1, Day(2))

    @test get_sim_length(DateTime, replacer1) != get_sim_length(DateTime, replacer2)

    with_logger(debug_logger) do
        dst_root_ext = nothing
        create_simulation(replacer1) do dst_root
            @test isdir(dst_root)

            efdc = load(joinpath(dst_root, "efdc.inp"), efdc_inp)
            @test efdc["C03"][1, "NTC"] == 2

            save(joinpath(dst_root, name(efdc_inp)), efdc)
            save(
                joinpath(dst_root, name(wqini_inp)),
                load(template, wqini_inp)
                #=
                load(
                    get_file_Path(template, name(wqini_inp)),
                    wqini_inp
                )
                =#
            )

            dst_root_ext = dst_root
        end

        @test !isdir(dst_root_ext)
    end

    ad = Dict(key=>align(template, d) for (key, d) in template)

    size_vec = Int[]
    begin_vec = DateTime[]
    end_vec = DateTime[]

    for a in values(ad)
        if a isa TimeArray
            push!(size_vec, size(a, 1))
            push!(begin_vec, timestamp(a)[1])
            push!(end_vec, timestamp(a)[end])
        else
            for aa in values(a)
                push!(size_vec, size(aa, 1))
                push!(begin_vec, timestamp(aa)[1])
                push!(end_vec, timestamp(aa)[end])    
            end
        end
    end

    for same_vec in [size_vec, begin_vec, end_vec]
        @test all(same_vec[1] .== same_vec[2:end])
    end

    td = efdc_lp_tempname()
    mkdir(td)

    qser = template[qser_inp]
    df = qser[keys(qser)[1]]
    df[1, "flow"] = 8964 # It's not recommended to modify "shared" content of template, here it's for test purpose
    save(joinpath(td, "qser.inp"), template[qser_inp])
    sub_template = SubSimulationTemplate(template, td)
    qser2 = load(sub_template, qser_inp)
    df2 = qser2[keys(qser2)[1]]
    @test df[1, "flow"] == 8964

    rm(td, recursive=true)


    for ftype in [qser_inp, wqpsc_inp]
        d = load(template, ftype)
        ad = align(template, d)
        k = keys(d)[1]
        df = d[k]
        ta = ad[k]
        time_key = TimeSeries.timestamp(ta)[1]
        col_key = TimeSeries.colnames(ta)[1]
        set_ta!(ta, time_key, col_key, 8964)
        update!(template, d, ad)
        
        if ftype == qser_inp
            @test d[k][1, col_key] == values(ta[time_key][col_key])[1,1] / 3600
        else
            @test d[k][1, col_key] == values(ta[time_key][col_key])[1,1]
        end
    end

end