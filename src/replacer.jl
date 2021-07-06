
struct Replacer <: RunnerFunc
    template::SimulationTemplate
    replace_map::Dict{Type, AbstractFile}
end

function Replacer(template::SimulationTemplate, replace_vec::AbstractVector{<:Type})
    replace_map = Dict{Type, AbstractFile}()
    for ftype in replace_vec
        p = joinpath(template.input_root, name(ftype))
        replace_map[ftype] = load(p, ftype)
    end
    return Replacer(template, replace_map)
end


function Replacer(template::SimulationTemplate)
    return Replacer(template, Type[])
end

parent(r::Replacer) = r.template

function _create_simulation(replacer::Replacer, target=tempname())
    for (ftype, d) in replacer.replace_map
        fp = joinpath(target, name(ftype))
        if isfile(fp)
            rm(fp)
        end
        save(fp, d)
        @debug "replace file $fp"
    end
end

function create_simulation(replacer::Replacer, target=tempname())
    create_simulation(replacer.template, target)
    _create_simulation(replacer, target)
    return target
end

function Base.show(io::IO, r::Replacer)
    base_text = "template=$(r.template), keys(replace_map)=$(keys(r.replace_map))"
    extra_text_vec = String[]
    if efdc_inp in keys(r.replace_map)
        begin_day_day = get_begin_day(Day, r)
        begin_day_date = get_begin_day(DateTime, r)

        sim_length_day = get_sim_length(Day, r)
        sim_length_date = get_sim_length(DateTime, r)

        restarting = is_restarting(r)

        text = "restarting->$restarting, begin_day->$begin_day_day, sim_length->$sim_length_day, range->$begin_day_date-->$sim_length_date"
        push!(extra_text_vec, text)
    end

    extra_text = join(extra_text_vec, ",")
    print(io, "Replacer($base_text, $extra_text)")
end

"""
Replacer's copy will not copy template.
"""
function Base.copy(r::Replacer)
    return Replacer(r.template, deepcopy(r.replace_map))
end

function Base.copy(r::Replacer, copy_keys::AbstractVector{<:Type})
    replace_map = copy(r.replace_map) # shallow copy
    for key in copy_keys
        replace_map[key] = deepcopy(r.replace_map[key])
    end
    return Replacer(r.template, replace_map)
end

# We will not implement `Int` dispatch to prevent ambiguous problem which had happened in Python version.
# If someone really need Int based operation, manipuate DataFrame directly.

function set_begin_day!(r::Replacer, begin_r_day::Day)
    C03 = r.replace_map[efdc_inp].df_map["C03"]
    C03[1, "TBEGIN"] = begin_r_day.value
    return r
end

function set_begin_day!(r::Replacer, begin_day::DateTime)
    C03 = r.replace_map[efdc_inp].df_map["C03"]
    C03[1, "TBEGIN"] = Day(begin_day - r.template.reference_time).value
    return r
end

function set_sim_length!(r::Replacer, sim_length::Day)
    C03 = r.replace_map[efdc_inp].df_map["C03"]
    C03[1, "NTC"] = sim_length.value
    return r
end

function set_sim_length!(r::Replacer, end_day::DateTime)
    C03 = r.replace_map[efdc_inp].df_map["C03"]
    C03[1, "NTC"] = Day(end_day - r.template.reference_time).value - C03[1, "TBEGIN"]
    return r
end

function get_begin_day(::Type{Day}, r::Replacer)
    C03 = r.replace_map[efdc_inp].df_map["C03"]
    return Day(C03[1, "TBEGIN"])
end

function get_begin_day(::Type{DateTime}, r::Replacer)
    return r.template.reference_time + get_begin_day(Day, r)
end

function get_sim_length(::Type{Day}, r::Replacer)
    C03 = r.replace_map[efdc_inp].df_map["C03"]
    return Day(C03[1, "NTC"])
end

function get_sim_length(::Type{DateTime}, r::Replacer)
    return get_begin_day(DateTime, r) + get_sim_length(Day, r)
end

function is_restarting(r::Replacer)
    ISRESTI = r.replace_map[efdc_inp].df_map["C02"][1, "ISRESTI"]
    if ISRESTI == 1
        return true
    elseif ISRESTI == 0
        return false
    else
        error("Unvalid value ISRESTI=$ISRESTI")
    end
end

function set_restarting!(r::Replacer, restarting::Bool)
    C02 = r.replace_map[efdc_inp].df_map["C02"]
    C02[1, "ISRESTI"] = restarting ? 1 : 0
    return r
end

function add_begin_day!(r::Replacer, d::Day)
    return set_begin_day!(r, get_begin_day(Day, r) + d)
end

function add_begin_day!(r::Replacer)
    d = get_sim_length(Day, r)
    return add_begin_day!(r, d)
end


set_begin_day!(r::Runner, x) = set_begin_day!(parent(r), x)
set_sim_length!(r::Runner, x) = set_sim_length!(parent(r), x)
get_begin_day(T, r::Runner) = get_begin_day(T, parent(r))
get_sim_length(T, r::Runner) = get_sim_length(T, parent(r))
is_restarting(r::Runner) = is_restarting(parent(r))
set_restarting!(r::Runner, x) = set_restarting!(parent(r), x)
add_begin_day!(r::Runner, x) = add_begin_day!(parent(r), x)
add_begin_day!(r::Runner) = add_begin_day!(parent(r))

copy_replacer(r::Replacer) = copy(r)
copy_replacer(r::Runner) = copy_replacer(parent(r))
