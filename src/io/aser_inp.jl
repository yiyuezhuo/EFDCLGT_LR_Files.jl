
struct aser_inp <: AbstractFile
    comment_lines::Vector{String}
    df::DataFrame
end

function load(io::IO, ::Type{aser_inp})
    aser_header_txt = "time	pressure	temperature	humidity	rain	evaporate	sun	cloud"
    aser_header = split(aser_header_txt, "\t")
    
    comment_lines = Iterators.takewhile(line->line[1]=='#', eachline(io, keep=true)) |> collect
    seek(io, sum(length, comment_lines))
    df = CSV.File(io, header=false) |> DataFrame
    rename!(df, aser_header)
    return aser_inp(strip.(comment_lines), df)
end

function save(io::IO, d::aser_inp)
    save(io, d.comment_lines)
    save(io, d.df)
end

name(::Type{aser_inp}) = "aser.inp"
time_key(::Type{aser_inp}) = :time
