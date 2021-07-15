
module _wqini_inp_WQWCRST_OUT

export wqini_inp, WQWCRST_OUT
using DataFrames
import ..EFDCLGT_LR_Files: AbstractFile, load, save, CSV, name
using DateDataFrames

abstract type AbstractWqRestartFile <: AbstractFile end

struct wqini_inp <: AbstractWqRestartFile
    header::Vector{String}
    df::DataFrame
end


function load(io::IO, ::Type{<:AbstractWqRestartFile})
    lines = eachline(io)
    first_lines = Iterators.take(lines, 4) |> collect

    buf = IOBuffer(join([replace(strip(line), "\t"=>" ") for line in lines], "\n")) # TODO: implement a specialized parser to avoid these ugly hacks.
    seek(buf, 0)

    table = CSV.File(buf, header=false, delim=" ", ignorerepeated=true)
    df = DataFrame(table)
    rename!(df, split(first_lines[end]))

    return wqini_inp(first_lines[1:end-1], df)
end

function save(io::IO, d::AbstractWqRestartFile)
    save(io, d.header)
    # write(io, "\n")
    save(io, d.df, header=true)
end

name(::Type{wqini_inp}) = "wqini.inp"

struct WQWCRST_OUT <: AbstractWqRestartFile
    header::Vector{String}
    df::DataFrame
end

name(::Type{WQWCRST_OUT}) = "WQWCRST.OUT"


end

using ._wqini_inp_WQWCRST_OUT
