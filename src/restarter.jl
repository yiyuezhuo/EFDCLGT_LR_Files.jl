
const restart_map = Dict(
    "RESTART.OUT" => "RESTART.INP",
    "TEMPBRST.OUT" => "TEMPB.RST",
    "WQWCRST.OUT" => "wqini.inp"
)

struct Restarter <: RunnerFunc
    replacer::Replacer
    root_completed::String
    Restarter(replacer::Replacer, root_completed::String) = begin
        @assert efdc_inp in keys(replacer)
        @assert is_restarting(replacer)
        new(replacer, root_completed)
    end
end

parent(r::Restarter) = r.replacer

function create_simulation(restarter::Restarter, target=efdc_lp_tempname())
    replacer = restarter.replacer
    name_set = Set([name(ftyp) for ftyp in keys(replacer)])

    create_simulation(replacer.template, target)

    for (out_name, inp_name) in restart_map
        if !(inp_name in name_set)
            src_p = joinpath(restarter.root_completed, out_name)
            dst_p = joinpath(target, inp_name)
            if isfile(dst_p)
                rm(dst_p)
            end
            cp(src_p, dst_p)
            @assert isfile(dst_p)
            # @debug "copy file $src_p -> $dst_p"
        end
    end

    replace_file(replacer, target)
end

function Base.show(io::IO, r::Restarter)
    print(io, "Restarter(replacer=$(r.replacer), root_completed=$(r.root_completed))")
end

function Base.copy(restarter::Restarter)
    return Restarter(copy(restarter.replacer), restarter.root_completed)
end

function load(restarter::Restarter, ftype::Type{<:AbstractFile})
    return load(joinpath(restarter.root_completed, name(ftype)), ftype)
end
