
struct SimulationTemplate{T}
    input_root::String
    exe_name::String
    non_modified_files::Vector{String}
    reference_time::T
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

    return SimulationTemplate(input_root, exe_name, non_modified_files, reference_time)
end

function create_simulation(template::SimulationTemplate, target=tempname())
    if !isdir(target)
        mkdir(target)
    end
    for file_name in [template.non_modified_files; [template.exe_name]]
        src_p = joinpath(template.input_root, file_name)
        dst_p = joinpath(target, file_name)
        symlink(src_p, dst_p)
    end
    println("symlink env: $(template.input_root) -> $target") # TODO: use logging
    return target
end

const restart_map = Dict(
    "RESTART.OUT" => "RESTART.INP",
    "TEMPBRST.OUT" => "TEMPB.RST",
    "WQWCRST.OUT" => "wqini.inp"
)

function setup_restart(src_root, dst_root)
    for (out_name, inp_name) in restart_map
        src_p = joinpath(src_root, out_name)
        dst_p = joinpath(dst_root, inp_name)
        if isfile(dst_p)
            rm(dst_p)
        end
        cp(src_p, dst_p)
        @assert isfile(dst_p)
    end
    println("copy restart files: $src_root -> $dst_root") # TODO: use logging
end

# We will not define a dispatch on template to use `template.input_root` since 
# the grand template may don't have restart files.