
struct Restarter <: RunnerFunc
    replacer::Replacer
    root_completed::String
    Restarter(replacer::Replacer, root_completed::String) = begin
        @assert efdc_inp in replacer.replace_map
        @assert is_restarting(replacer.restarter)
        new(replacer, root_completed)
    end
end

function create_simulation(restarter::Restarter, target=tempname())
    replacer = restarter.replacer
    name_set = Set([name(ftyp) for ftyp in keys(replacer.replace_map)])

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
        end
        @debug "copy file $src_p -> $dst_p"
    end

    _create_simulation(replacer, target)
end