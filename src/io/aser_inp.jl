
struct aser_inp <: AbstractFile
    comment_lines::Vector{String}
    df::DataFrame
    end_line::String
end

function load(io::IO, ::Type{aser_inp})
    aser_header_txt = "time	pressure	temperature	humidity	rain	evaporate	sun	cloud"
    aser_header = split(aser_header_txt, "\t")
    
    #=
    comment_lines = Iterators.takewhile(line->line[1]=='#', eachline(io, keep=true)) |> collect
    seek(io, sum(length, comment_lines))
    =#
    lines = eachline(io, keep=true) |> collect
    comment_lines = Iterators.takewhile(line->line[1]=='#', lines) |> collect
    df_str = join(lines[length(comment_lines)+1:end-1], "\n")
    end_line = lines[end]

    df = CSV.File(IOBuffer(df_str), header=false) |> DataFrame
    rename!(df, aser_header)
    return aser_inp(strip.(comment_lines), df, end_line)
end

function save(io::IO, d::aser_inp)
    save(io, d.comment_lines)
    save(io, d.df)
end

name(::Type{aser_inp}) = "aser.inp"
time_key(::Type{aser_inp}) = :time

value_align(::Type{aser_inp}, ta::TimeArray) = ta

function align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, d::aser_inp)
    ta = time_align2(dt, FT, DT, d.df, time_key(aser_inp))
    return value_align(aser_inp, ta)
end
