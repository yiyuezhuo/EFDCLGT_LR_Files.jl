
struct FlowLevel
    level::Int
    df::DataFrame
end

function FlowLevel(lines::AbstractVector{<:AbstractVector{<:AbstractString}})
    level = parse(Int, lines[1][1])

    #=
    mat = mapreduce(line->parse.(Float64, line), hcat, lines[2:end])
    df = DataFrame(mat', ["time", "flow"])
    =#
    # 150ms
    
    # 55ms
    df = _read_table(lines[2:end], ["time", "flow"])
    #=
    buf = join(join.(lines[2:end], " "), "\n") |> IOBuffer
    df = CSV.File(buf, header=false, delim=" ") |> DataFrame
    rename!(df, ["time", "flow"])
    =#

    return FlowLevel(level, df)
end

function save(io::IO, fl::FlowLevel)
    write(io, "$(fl.level)\n")
    save(io, fl.df)
end

struct Flow
    headers::Vector{String}
    dl_vec::Vector{FlowLevel}
end

#=
function Flow(word_vec::AbstractVector{<:AbstractVector{<:AbstractString}})
    # @show length(word_vec) word_vec[1] word_vec[2]
    headers = word_vec[1]
    df = DataFrame(parse.(Float64, reduce(vcat, word_vec[2:end])), ["time", "flow"])
    return Flow(headers, df)
end
=#

name(flow::Flow) = flow.headers[end]
function save(io::IO, flow::Flow)
    write(io, join(flow.headers, " "))
    write(io, "\n")
    for dl in flow.dl_vec
        save(io, dl)
    end
end

struct qser_inp <: AbstractFile
    node_list::Vector{Union{Flow, Vector{String}}}
    df_map::Dict{Tuple{String, Int}, DataFrame}
end

function qser_inp(node_list::Vector{Union{Flow, Vector{String}}})
    df_map = Dict{Tuple{String, Int}, DataFrame}()
    for node in node_list
        if node isa Flow
            for dl in node.dl_vec
                # @show length(node_list) node.headers dl.level size(dl.df)
                df_map[name(node), dl.level] = dl.df
            end
        end
    end
    return qser_inp(node_list, df_map)
end

name(::Type{qser_inp}) = "qser.inp"
time_key(::Type{qser_inp}) = :time

function load(io::IO, ::Type{qser_inp})
    node_list = Union{Flow, Vector{String}}[]
    comment_building = String[]
    header = String[]
    flow_level_building = Vector{String}[]
    flow_level_vec = FlowLevel[]
    for line in eachline(io)
        if line[1] == '#'
            push!(comment_building, line)
        else
            if length(comment_building) > 0
                push!(node_list, comment_building)
                comment_building = String[]
            end

            words = split(line)

            if length(words) == 2
                push!(flow_level_building, words)
            elseif length(words) == 1
                if length(flow_level_building) > 0
                    flow_level = FlowLevel(flow_level_building)
                    push!(flow_level_vec, flow_level)
                end
                flow_level_building = [words]
            else
                if length(header) > 0
                    flow_level = FlowLevel(flow_level_building)
                    push!(flow_level_vec, flow_level)
                    flow = Flow(header, flow_level_vec)
                    push!(node_list, flow)

                    flow_level_building = Vector{String}[]
                    flow_level_vec = FlowLevel[]
                end
                header = words
            end
        end
    end

    if length(flow_level_building) > 0
        flow_level = FlowLevel(flow_level_building)
        push!(flow_level_vec, flow_level)
        flow = Flow(header, flow_level_vec)
        push!(node_list, flow)
    end

    if length(comment_building) > 0
        push!(node_list, comment_building)
    end

    return qser_inp(node_list)
end

function save(io::IO, d::qser_inp)
    for node in d.node_list
        save(io, node)
    end
end

