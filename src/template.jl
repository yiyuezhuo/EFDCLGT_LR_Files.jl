abstract type AbstractSimulationTemplate <: RunnerFunc end

struct SimulationTemplate <: AbstractSimulationTemplate
    _input_root::String
    exe_name::String
    non_modified_files::Vector{String}
    reference_time::DateTime
    total_begin::Day
    total_length::Day
    FT::Type # EX: FT=Day => 1601.1 -> 1601.1 day 
    DT::Type # EX: DT=Hour => rounded to Hour
    _share_map::Dict{Type, AbstractFile} # share_map is expected to not be modified.
    qser_ref::Dict{Tuple{String, Int}, DateDataFrame}
    wqpsc_ref::Dict{String, DateDataFrame}

    #=
    # TODO: there fields are not consistent with the pricinple of removing unnessary hash table from code.
    ijk_to_flow_name::Dict{Tuple{Int, Int, Int}, String}
    flow_name_to_ijk::Dict{String, Tuple{Int, Int, Int}}
    inflow_name_to_keys::Dict{String, Vector{Tuple{String, Int}}}
    ijk_to_overflow_idx::Dict{Tuple{Int, Int, Int}, Int}
    overflow_idx_to_ijk::Vector{Tuple{Int, Int, Int}}
    =#
end

function SimulationTemplate(input_root, FT::Type{<:Period}, DT::Type{<:Period}, share_vec::AbstractVector{<:Type}, 
                            load_qser_ad=qser_inp in share_vec,
                            load_wqpsc_ad=wqpsc_inp in share_vec)
    dir_root = dirname(input_root)
    model_name_vec = [name for name in readdir(dir_root) if endswith(name, ".model")]
    @assert length(model_name_vec) == 1
    model_name = model_name_vec[1]

    xdoc = parse_file(joinpath(dir_root, model_name))
    xroot = root(xdoc)
    tag = find_element(xroot, "ReferenceTime")
    reference_time_str = content(tag)
    reference_time = DateTime(reference_time_str, dateformat"Y/m/d H:M:S")

    exe_name_vec = [name for name in readdir(input_root) if endswith(name, ".exe")]
    @assert length(model_name_vec) == 1
    exe_name = exe_name_vec[1]

    non_modified_files::Vector{String} = open(joinpath(dirname(@__DIR__), "data", "non_modified_files.json")) do f
        return JSON.parse(read(f, String))
    end

    efdc = load(joinpath(input_root, name(efdc_inp)), efdc_inp)
    total_begin = Day(efdc["C03"][1, "TBEGIN"])
    total_length = Day(efdc["C03"][1, "NTC"])

    share_map = Dict{Type{<:AbstractFile}, AbstractFile}()
    for ftype in share_vec
        share_map[ftype] = load(joinpath(input_root, name(ftype)), ftype)
    end

    t_arg = (reference_time, FT, DT)

    qser_ref = load_qser_ad ? align(t_arg..., share_map[qser_inp]) : Dict{Tuple{String, Int}, DateDataFrame}()
    wqpsc_ref = load_wqpsc_ad ? align(t_arg..., share_map[wqpsc_inp]) : Dict{String, DateDataFrame}()

    return SimulationTemplate(input_root, exe_name, non_modified_files, reference_time, total_begin, total_length, FT, DT, share_map, qser_ref, wqpsc_ref)
end

SimulationTemplate(input_root, FT::Type{<:Period}, DT::Type{<:Period}) = SimulationTemplate(input_root, FT, DT, Type{<:AbstractFile}[])

function get_file_path(t::SimulationTemplate, file_name::String)
    return joinpath(t._input_root, file_name)
end

function _log_create_simulation(t::SimulationTemplate, target)
    @debug "symlink env: $(t._input_root) -> $target"
end

function Base.show(io::IO, t::SimulationTemplate)
    print(io, "SimulationTempate(_input_root=$(t._input_root), exe_name=$(t.exe_name), reference_time=$(t.reference_time), length(non_modified_files)=$(length(t.non_modified_files))), keys->$(keys(t))")
end

function get_file_path(t::AbstractSimulationTemplate, ftype::Type{<:AbstractFile})
    return get_file_path(t, name(ftype))
end

function load(t::AbstractSimulationTemplate, ftype::Type{<:AbstractFile})
    return load(get_file_path(t, ftype), ftype)
end

function parent(t::AbstractSimulationTemplate)
    error("SimulationTemplate is most respectful JZM elder toad! How dare the dumb XJP pig.")
end

function create_simulation(func::Function, template_like)
    target = efdc_lp_tempname()
    create_simulation(template_like, target)
    res = func(target)
    rm(target, recursive=true)
    return res
end

function create_simulation(template::AbstractSimulationTemplate, target=efdc_lp_tempname())
    if !isdir(target)
        mkdir(target)
    end
    # for file_name in [template.non_modified_files; [template.exe_name]]
    for file_name in template.non_modified_files
        src_p = get_file_path(template, file_name)
        dst_p = joinpath(target, file_name)
        symlink(src_p, dst_p)
    end
    _log_create_simulation(template, target)
    return target
end

function get_exe_path(t::AbstractSimulationTemplate)
    return joinpath(t._input_root, t.exe_name)
end

function get_total_begin(::Type{Day}, t::AbstractSimulationTemplate)
    return t.total_begin
end

function get_total_begin(::Type{DateTime}, t::AbstractSimulationTemplate)
    return t.reference_time + t.total_begin
end

function get_total_length(::Type{Day}, t::AbstractSimulationTemplate)
    return t.total_length
end

function get_total_length(::Type{DateTime}, t::AbstractSimulationTemplate)
    return t.reference_time + t.total_begin + t.total_length
end

get_exe_path(r::Runner) = get_exe_path(parent(r))
get_total_begin(T, r::Runner) = get_total_begin(T, parent(r))
get_total_length(T, r::Runner) = get_total_length(T, parent(r))

function convert_time(template::AbstractSimulationTemplate, time_vec::Vector{T}) where T <: Period
    return time_vec - round(get_total_begin(Day, template), T) 
end

function convert_time(template::AbstractSimulationTemplate, ST::Type{<:Period}, DT::Type{<:Period}, time::AbstractFloat)
    # return _convert_time(ST, DT, time) - round(get_total_begin(Day, template), T) 
    return convert_time(template, _convert_time(ST, DT, time))
end

function convert_time(template::AbstractSimulationTemplate, ST::Type{Day}, ::Type{DateTime}, time::AbstractFloat)
    delta = _convert_time(ST, time) # ms
    return template.reference_time + delta
end

function time_align(template::AbstractSimulationTemplate, df::DataFrame, key; kwargs...)
    return time_align(template.reference_time, template.FT, template.DT, df, key; kwargs...)
end

function align(template::AbstractSimulationTemplate, d)
    return align(template.reference_time, template.FT, template.DT, d)
end

master_map(t::SimulationTemplate) = t._share_map

struct SubSimulationTemplate <: AbstractSimulationTemplate
    template::AbstractSimulationTemplate
    _override_root::String

    _share_map::Dict{Type, AbstractFile} # share_map is expected to not be modified.
    qser_ref::Dict{Tuple{String, Int}, DateDataFrame}
    wqpsc_ref::Dict{String, DateDataFrame}
end

function SubSimulationTemplate(template::AbstractSimulationTemplate, override_root::String, 
                            share_vec::AbstractVector{<:Type}, 
                            load_qser_ad=qser_inp in share_vec,
                            load_wqpsc_ad=wqpsc_inp in share_vec)
    share_map = Dict{Type{<:AbstractFile}, AbstractFile}()

    for ftype in share_vec
        share_map[ftype] = load(joinpath(override_root, name(ftype)), ftype)
    end

    t_arg = (template.reference_time, template.FT, template.DT)

    qser_ref = load_qser_ad ? align(t_arg..., share_map[qser_inp]) : Dict{Tuple{String, Int}, DateDataFrame}()
    wqpsc_ref = load_wqpsc_ad ? align(t_arg..., share_map[wqpsc_inp]) : Dict{String, DateDataFrame}()

    return SubSimulationTemplate(template, override_root, share_map, qser_ref, wqpsc_ref)
end

function Base.getproperty(t::SubSimulationTemplate, key::Symbol)
    if key in fieldnames(SubSimulationTemplate)
        if key in (:qser_ref, :wqpsc_ref)
            ret = getfield(t, key)
            if isempty(ret)
                return getfield(t.template, key)
            else
                return ret
            end
        end
        return getfield(t, key)
    end
    return getfield(t.template, key)
end

function Base.getindex(t::SubSimulationTemplate, key)
    if key in keys(t._share_map)
        return t._share_map[key]
    else
        return t.template._share_map[key]
    end
end

function master_map(t::SubSimulationTemplate)
    return merge(master_map(t.template), t._share_map)
end

function get_file_path(t::SubSimulationTemplate, file_name::String)
    p = joinpath(t._override_root, file_name)
    if isfile(p)
        return p
    end
    return get_file_path(t.template, file_name)
end

function _log_create_simulation(t::SubSimulationTemplate, target)
    @debug "symlink env: $((t.template._input_root, t._override_root)) -> $target"
end

function Base.show(io::IO, t::SubSimulationTemplate)
    print(io, "SubSimulationTemplate(template=$(t.template), _override_root=$(t._override_root))")
end

update!(template::AbstractSimulationTemplate, d::AbstractFile, new_value) = update!(template.reference_time, d, new_value)

function get_template(t::AbstractSimulationTemplate)
    return t
end

function get_template(r::Runner)
    return get_template(parent(r))
end
