
abstract type AbstractFile end

function load(path, T::Type{<:AbstractFile})
    open(path) do f
        return load(f, T)
    end
end

function load(::IO, D::Type{<:AbstractFile})
    error("Unsupporedted load format $D")
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

function save(io::IO, d::DataFrame; header=false, delim=" ")
    CSV.write(io, d, append=true, header=header, delim=delim)
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

function resample_nearest(dtv::Vector{DateTime}, r::StepRange, delta::Period)
    dt = r.start
    
    dt_building = DateTime[]
    idx_building = Int[]

    for idx in 2:length(dtv)
        while dt + delta < dtv[idx-1]
            dt += r.step
        end
        while dt + delta < dtv[idx]
            push!(dt_building, dt)
            push!(idx_building, idx-1)
            
            dt += r.step
        end
    end
    while dt < r.stop
        push!(dt_building, dt)
        push!(idx_building, length(dtv))
        
        dt += r.step
    end
    return dt_building, idx_building
end

function resample_nearest(dtv::Vector{DateTime}, step::PT, delta::Period) where PT <: Period
    r_begin = round(dtv[1], PT)
    r_end = round(dtv[end], PT)
    return resample_nearest(dtv, r_begin:step:r_end, delta)
end

function time_align2(dt::DateTime, FT::Type{<:Period}, step::Period, df::AbstractDataFrame, key; middle=true)
    delta = middle ? Millisecond(step) / 2 : Millisecond(0)

    dtv = convert_time.(dt, FT, DateTime, df[!, key])
    tv, idx_vec = resample_nearest(dtv, step, delta)
    mat = Matrix{Float64}(undef, length(tv), size(df, 2))

    for (idx, k) in enumerate(names(df))
        @views copy!(mat[:, idx], df[idx_vec, k])
    end
    ta = TimeArray(tv, mat, names(df))

    return ta
end

function time_align2(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Period}, df::AbstractDataFrame, key; middle=true)
    step = DT(1)
    return time_align2(dt, FT, step, df, key; middle=middle)
end

"""
EX:
time_align(df, "time", Day, DateTime) # "lossless" datetime
time_align(df, "time", Day, Hour) # datetime rounded to hour

For pairs, this requires:

1687.25	0.02618311
1687.291666625	0.02618311
1687.2916666666667	0.02616940
1687.3333332916666	0.02616940

while 		

1718.333333	0
1718.375	0
1718.375	0
1718.416667	0

is not valid. (But it's 0 so make no difference anyway.)

# TODO: -1 ms from pair before this process?
"""
function time_align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, df::AbstractDataFrame, key)
    #=
    df = copy(df)
    df[!, :date] = convert_time.(dt, FT, DT, df[!, key])
    ta = TimeArray(df, timestamp=:date)
    =#
    # The above implementation use mapreduce, resulting Any type, the performance is terrible.

    tv = convert_time.(dt, FT, DT, df[!, key])
    # mat = mapreduce((n)->df[!, n], hcat, names(df))
    mat = Matrix{Float64}(undef, size(df, 1), size(df, 2))
    for (idx, k) in enumerate(names(df))
        @views copy!(mat[1:end, idx], df[!, k])
    end
    ta = TimeArray(tv, mat, names(df))

    mask = Vector{Bool}(undef, length(ta))
    ts = TimeSeries.timestamp(ta)
    mask[1] = true
    for i in 2:length(ts)
        mask[i] = ts[i] != ts[i-1]
    end

    ta_dedup = ta[mask]
    return ta_dedup
end

"""
value_align will rescale units and possibly drop the float time column for convenient
"""
function value_align(T::Type{<:AbstractFile}, ::TimeArray)
    error("value_align is unsupported for $T")
end

function align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, d::FileType) where FileType <: PureDataFrameFile
    ta = time_align(dt, FT, DT, d.df, time_key(FileType))
    return value_align(FileType, ta)
end

function _read_table(lines::AbstractVector{<:AbstractVector{<:AbstractString}}, headers)
    buf = join(join.(lines, " "), "\n") |> IOBuffer
    df = CSV.File(buf, header=false, delim=" ") |> DataFrame
    rename!(df, headers)
    return df
end

Base.getindex(d::AbstractFile, key::Symbol) = d[string(key)]
function Base.getindex(d::AbstractFile, key::String)
    error("Base.getindex is not supported for $(typeof(d))")
end

abstract type AbstractMapDfFile <: AbstractFile end

function Base.show(io::IO, d::T) where T <: AbstractMapDfFile
    print(io, "$T(keys->(")
    size_vec = []
    for k in keys(d)
        print(io, "$k,")
        push!(size_vec, size(d[k]))
    end
    for i in 2:length(size_vec)
        @assert size_vec[1] == size_vec[i]
    end
    print(io, "), value_size->$(size_vec[1])")
    print(io, ")")
end
