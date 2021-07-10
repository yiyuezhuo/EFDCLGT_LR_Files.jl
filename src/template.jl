
struct SimulationTemplate <: RunnerFunc
    input_root::String
    exe_name::String
    non_modified_files::Vector{String}
    reference_time::DateTime
    total_begin::Day
    total_length::Day
    FT::Type # EX: FT=Day => 1601.1 -> 1601.1 day 
    DT::Type # EX: DT=Hour => rounded to Hour
    _share_map::Dict{Type, AbstractFile} # share_map is expected to not be modified.
end

function SimulationTemplate(input_root, FT::Type{<:Period}, DT::Type{<:Period}, share_vec::AbstractVector{<:Type})
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

    return SimulationTemplate(input_root, exe_name, non_modified_files, reference_time, total_begin, total_length, FT, DT, share_map)
end

SimulationTemplate(input_root, FT::Type{<:Period}, DT::Type{<:Period}) = SimulationTemplate(input_root, FT, DT, Type{<:AbstractFile}[])

function parent(t::SimulationTemplate)
    error("SimulationTemplate is most respectful elder toad! How dare Xi, the white pig!")
end

function create_simulation(func::Function, template_like)
    target = tempname()
    create_simulation(template_like, target)
    res = func(target)
    rm(target, recursive=true)
    return res
end

function create_simulation(template::SimulationTemplate, target=tempname())
    if !isdir(target)
        mkdir(target)
    end
    # for file_name in [template.non_modified_files; [template.exe_name]]
    for file_name in template.non_modified_files
        src_p = joinpath(template.input_root, file_name)
        dst_p = joinpath(target, file_name)
        symlink(src_p, dst_p)
    end
    @debug "symlink env: $(template.input_root) -> $target"
    return target
end

const restart_map = Dict(
    "RESTART.OUT" => "RESTART.INP",
    "TEMPBRST.OUT" => "TEMPB.RST",
    "WQWCRST.OUT" => "wqini.inp"
)

# We will not define a dispatch on template to use `template.input_root` since 
# the grand template may don't have restart files.

function Base.show(io::IO, t::SimulationTemplate)
    print(io, "SimulationTempate(input_root=$(t.input_root), exe_name=$(t.exe_name), reference_time=$(t.reference_time), length(non_modified_files)=$(length(t.non_modified_files))), keys->$(keys(t))")
end

function get_exe_path(t::SimulationTemplate)
    return joinpath(t.input_root, t.exe_name)
end

function get_total_begin(::Type{Day}, t::SimulationTemplate)
    return t.total_begin
end

function get_total_begin(::Type{DateTime}, t::SimulationTemplate)
    return t.reference_time + t.total_begin
end

function get_total_length(::Type{Day}, t::SimulationTemplate)
    return t.total_length
end

function get_total_length(::Type{DateTime}, t::SimulationTemplate)
    return t.reference_time + t.total_begin + t.total_length
end

get_exe_path(r::Runner) = get_exe_path(parent(r))
get_total_begin(T, r::Runner) = get_total_begin(T, parent(r))
get_total_length(T, r::Runner) = get_total_length(T, parent(r))

function convert_time(template::SimulationTemplate, time_vec::Vector{T}) where T <: Period
    return time_vec - round(get_total_begin(Day, template), T) 
end

function convert_time(template::SimulationTemplate, ST::Type{<:Period}, DT::Type{<:Period}, time::AbstractFloat)
    # return _convert_time(ST, DT, time) - round(get_total_begin(Day, template), T) 
    return convert_time(template, _convert_time(ST, DT, time))
end

function convert_time(template::SimulationTemplate, ST::Type{Day}, ::Type{DateTime}, time::AbstractFloat)
    delta = _convert_time(ST, time) # ms
    return template.reference_time + delta
end

function time_align(template::SimulationTemplate, df::DataFrame, key)
    return time_align(template.reference_time, template.FT, template.DT, df, key)
end

function align(template::SimulationTemplate, d)
    return align(template.reference_time, template.FT, template.DT, d)
end

master_map(t::SimulationTemplate) = t._share_map
