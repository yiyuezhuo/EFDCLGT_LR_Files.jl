using Base: with_logger
using Test
using EFDCLGT_LR_Files
using EFDCLGT_LR_Files: name

using Dates
using Logging

debug_logger = SimpleLogger(stdout, Logging.Debug)
default_logger = global_logger()

template = SimulationTemplate(ENV["WATER_ROOT"], Day, Hour)

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
            @test efdc.df_map["C03"][1, "NTC"] == 2

            save(joinpath(dst_root, name(efdc_inp)), efdc)
            save(
                joinpath(dst_root, name(wqini_inp)),
                load(
                    joinpath(template.input_root, name(wqini_inp)),
                    wqini_inp
                )
            )

            dst_root_ext = dst_root
        end

        @test !isdir(dst_root_ext)
    end

end