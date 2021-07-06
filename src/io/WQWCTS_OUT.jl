
struct WQWCTS_OUT <: AbstractFile
    df::DataFrame
end

name(::Type{WQWCTS_OUT}) = "WQWCTS.OUT"

function load(io::IO, ::Type{WQWCTS_OUT})
    return CSV.File(io, header=true, delim=" ", ignorerepeated=true) |> DataFrame |> WQWCTS_OUT
end

function save(io::IO, d::WQWCTS_OUT)
    # However, we don't need to overwrite `WQWCTS.OUT` at this time.
    save(io, d.df, header=true)
end
