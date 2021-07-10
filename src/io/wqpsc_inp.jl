
module _wqpsc_inp

import ..EFDCLGT_LR_Files: AbstractFile, load, save, CSV, name, align, value_align, TimeArray, time_align, TimeSeries
export wqpsc_inp

using DataFrames
using Dates

wqpsc_header_txt1 = "TIME	CHC	CHD	CHG	ROC	LOC	LDC	RDC	ROP	LOP	LDP	RDP	PO4	RON	LON	LDN	RDN	NH4	NO3"
wqpsc_header_txt2 = "SU      SA    COD     DO    TAM    FCB   DSE   PSE"
# wqpsc_header_txt2 = "usable_si unusable_si chemistry_demand_oxygen dissolved_oxygen active_metal EPEC dissolved_se grain_se"
wqpsc_header_txt = wqpsc_header_txt1 * " " * wqpsc_header_txt2
const wqpsc_header = split(wqpsc_header_txt)

struct Concentration
    headers::Vector{String}
    df::DataFrame
end

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

name(::Type{wqpsc_inp}) = "wqpsc.inp"
time_key(::Type{wqpsc_inp}) = :TIME

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

"""
There are strange fluctuation in wqpsc_inp data when water is not enough:

1   0   2   0   3   0 ->
0.5 0.5 1   1   1.5 1.5

However, following may be expected or not be expected:

1   0   0   0   ->
1/2 1/4 1/8 1/8
"""
function fluctuation_smooth!(mat::Matrix)
    for j=1:size(mat, 2), i=2:size(mat, 1)
        if mat[i, j] == 0 && mat[i-1, j] != 0
            mat[i, j] = mat[i-1, j] = mat[i-1, j] / 2
        end
    end
end

function value_align(::Type{wqpsc_inp}, ta::TimeArray)
    ta = ta[TimeSeries.colnames(ta)[2:end]] # remove time columns
    mat = values(ta)
    fluctuation_smooth!(mat)
    return ta
end

function align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, d::wqpsc_inp)
    rd = Dict{String, TimeArray}()
    for node in d.node_list
        df = node.df
        ta = time_align(dt, FT, DT, df, time_key(wqpsc_inp))
        ta = value_align(wqpsc_inp, ta)
        rd[name(node)] = ta
    end
    return rd
end

end

using ._wqpsc_inp
