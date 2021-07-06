
struct SimulationTemplate <: RunnerFunc
    input_root::String
    exe_name::String
    non_modified_files::Vector{String}
    reference_time::DateTime
    total_begin::Day
    total_length::Day
end

function SimulationTemplate(input_root)
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
    total_begin = Day(efdc.df_map["C03"][1, "TBEGIN"])
    total_length = Day(efdc.df_map["C03"][1, "NTC"])

    return SimulationTemplate(input_root, exe_name, non_modified_files, reference_time, total_begin, total_length)
end

function parent(t::SimulationTemplate)
    error("SimulationTemplate is most respectful elder toad! How dare Xi, the white pig!")
end

function create_simulation(func::Function, template_like)
    target=tempname()
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
    print(io, "SimulationTempate(input_root=$(t.input_root), exe_name=$(t.exe_name), reference_time=$(t.reference_time), length(non_modified_files)=$(length(t.non_modified_files)))")
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
