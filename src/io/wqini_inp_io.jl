
module wqini_inp_io

export wqini_inp
using DataFrames
import ..EFDCLGT_LR_Files: AbstractFile, load, save, CSV

struct wqini_inp <: AbstractFile
    header::Vector{String}
    df::DataFrame
end

function load(p, ::Type{wqini_inp})
    first_lines, table, df = open(p) do f
        first_lines = Iterators.take(eachline(f), 4) |> collect
        table = CSV.File(f, header=false)
        df = DataFrame(table)
        rename!(df, split(first_lines[end]))
        return first_lines, table, df
    end

    return wqini_inp(first_lines[1:end-1], df)
end

function save(io::IO, d::wqini_inp, )
    save(io, d.header)
    # write(io, "\n")
    save(io, d.df, writeheader=true)
end

end