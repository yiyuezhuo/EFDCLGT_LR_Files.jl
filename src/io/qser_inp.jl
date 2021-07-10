
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
    # df_map::Dict{Tuple{String, Int}, DataFrame}
end

function Base.getindex(d::qser_inp, key::Tuple{String, Int})
    key_name, key_idx = key
    for node in d.node_list
        if node isa Flow && name(node) == key_name
            return node.dl_vec[key_idx].df
        end
    end
    error("Can't find key $key")
end

Base.getindex(d::qser_inp, s::String, i::Int) = d[(s, i)]

function Base.keys(d::qser_inp)
    rv = Tuple{String, Int}[]
    for node in d.node_list
        if node isa Flow
            for dl in node.dl_vec
                push!(rv, (name(node), dl.level))
            end
        end
    end
    return rv
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

function value_align(::Type{qser_inp}, ta::TimeArray)
    # @show ta
    return ta[:flow] .* 3600  # m3/s -> m3/h
end

function align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, d::qser_inp)
    rd = Dict{Tuple{String, Int}, TimeArray}()
    for node in d.node_list
        if node isa Flow
            for dl in node.dl_vec
                df = dl.df
                ta = time_align2(dt, FT, DT, df, time_key(qser_inp))
                rd[name(node), dl.level] = value_align(qser_inp, ta)
            end
        end
    end
    return rd
end
