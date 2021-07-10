
module _wqpsc_inp

import ..EFDCLGT_LR_Files: AbstractFile, load, save, CSV, name
export wqpsc_inp

using DataFrames

wqpsc_header_txt1 = "TIME	CHC	CHD	CHG	ROC	LOC	LDC	RDC	ROP	LOP	LDP	RDP	PO4	RON	LON	LDN	RDN	NH4	NO3"
wqpsc_header_txt2 = "SU      SA    COD     DO    TAM    FCB   DSE   PSE"
# wqpsc_header_txt2 = "usable_si unusable_si chemistry_demand_oxygen dissolved_oxygen active_metal EPEC dissolved_se grain_se"
wqpsc_header_txt = wqpsc_header_txt1 * " " * wqpsc_header_txt2
const wqpsc_header = split(wqpsc_header_txt)

struct Concentration
    headers::Vector{String}
    df::DataFrame
end

#=
function Concentration(word_vec::AbstractVector{<:AbstractVector{<:AbstractString}})
    # @show length(word_vec) word_vec[1] word_vec[2]
    headers = word_vec[1]

    df = _read_table(lines[2:end], wqpsc_header)
    return Concentration(headers, df)
end
=#

name(con::Concentration) = con.headers[end]

function save(io::IO, con::Concentration)
    write(io, join(con.headers, " "))
    write(io, "\n")
    save(io, con.df)
end

struct wqpsc_inp <: AbstractFile
    node_list::Vector{Concentration}
    # df_map::Dict{String, DataFrame}
end

function Base.getindex(d::wqpsc_inp, key::String)
    for node in d.node_list
        if name(node) == key
            return node.df
        end
    end
    error("can't find $key")
end

#=
function wqpsc_inp(node_list::Vector{Concentration})
    df_map = Dict{String, DataFrame}()
    for node in node_list
        df_map[name(node)] = node.df
    end
    return wqpsc_inp(node_list, df_map)
end
=#

name(::Type{wqpsc_inp}) = "wqpsc.inp"
time_key(::Type{wqpsc_inp}) = :time

function load(io::IO, ::Type{wqpsc_inp})
    lines = io |> eachline |> collect
    n = length(lines)
    idx = 1
    node_list = Concentration[]
    while idx < n
        headers = split(lines[idx])
        if length(headers) == 0
            break
        end
        rows = parse(Int, headers[1])
        
        buf = IOBuffer(join(lines[idx+1: idx+rows], "\n"))
        df = CSV.File(buf, header=false, delim="\t", ignorerepeated=true) |> DataFrame
        rename!(df, wqpsc_header)
        con = Concentration(headers, df)

        push!(node_list, con)

        idx += rows + 1
    end
    return wqpsc_inp(node_list)
end

function save(io::IO, d::wqpsc_inp)
    for node in d.node_list
        save(io, node)
    end
end

end

using ._wqpsc_inp
