
abstract type AbstractFile end

function load(path, T::Type{<:AbstractFile})
    open(path) do f
        return load(f, T)
    end
end

function load(::IO, ::Type{<:AbstractFile})
    error("Unsupporedted load format $f")
end

function save(path, d::AbstractFile)
    open(path, "w") do f
        save(f, d)
    end
end

function save(::IO, ::AbstractFile)
    error("Unsupporedted save format $f")
end

function save(io::IO, d::Vector{String})
    write(io, join(d, "\n"))
    write(io, "\n")
end

function save(io::IO, d::DataFrame; header=false)
    CSV.write(io, d, append=true, header=header, delim=" ")
end

name(typ::Type{<:AbstractFile}) = error("Name of $typ is undefined")
time_key(typ::Type{<:AbstractFile}) = error("time_key of $type is undefined")

abstract type PureDataFrameFile <: AbstractFile end

function load(io::IO, FileType::Type{<:PureDataFrameFile})
    return CSV.File(io, header=true, delim=" ", ignorerepeated=true) |> DataFrame |> FileType
end

function save(io::IO, d::PureDataFrameFile)
    # However, we don't need to overwrite `WQWCTS.OUT` at this time.
    save(io, d.df, header=true)
end

"""
EX:
time_align(df, "time", Day, DateTime) # "lossless" datetime
time_align(df, "time", Day, Hour) # datetime rounded to hour
"""
function time_align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, df::DataFrame, key)
    df = copy(df)
    df[!, :date] = convert_time.(dt, FT, DT, df[!, key])
    ta = TimeArray(df, timestamp=:date)

    mask = Vector{Bool}(undef, length(ta))
    ts = TimeSeries.timestamp(ta)
    mask[1] = true
    for i in 2:length(ts)
        mask[i] = ts[i] != ts[i-1]
    end

    ta_dedup = ta[mask]
    return ta_dedup
end

function value_align(::Type{<:AbstractFile}, ta::TimeArray)
    error("align is unsupported for $(typeof(d))")
end

function align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, d::FileType) where FileType <: PureDataFrameFile
    ta = time_align(dt, FT, DT, d.df, time_key(FileType))
    println(FileType)
    return value_align(FileType, ta)
end
