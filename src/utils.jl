
const day_to_ms_coef = 24 * 3600_000

"""
Julia use Millisecond as general delta representation. Day to ms
"""
function _convert_time(::Type{Day}, time::AbstractFloat)
    # return Millisecond(Int.(time * day_to_ms_coef))
    return Millisecond(round(Int, time * day_to_ms_coef))
    # return Millisecond(ceil(Int, time * day_to_ms_coef))
end

"""
EX: _convert_time(Day, Hour, time) # a float value denoting day to Hour.
"""
function _convert_time(ST::Type, ::Type{T}, time::AbstractFloat) where T <: Period
    return round(_convert_time(ST, time), T)
end

function convert_time(dt::DateTime, ST::Type, ::Type{DateTime}, time::AbstractFloat)
    return dt + _convert_time(ST, time)
end

function convert_time(dt::DateTime, ST::Type, DT::Type{<:Period}, time::AbstractFloat)
    # return dt + round(_convert_time(ST, time), DT)
    return dt + floor(_convert_time(ST, time), DT)
end

"""
TimeSeries doesn't provide `setindex!`, so we provide a naive version.
"""
function set_ta!(ta::TimeArray, row_idx, col_idx, value)
    mat = values(ta)
    # @show row_idx col_idx
    mat[row_idx, col_idx] = value
end

function set_ta!(ta::TimeArray, dt::DateTime, col_idx::Int, value)
    # https://github.com/JuliaStats/TimeSeries.jl/blob/3211ad5f0cceed0555b99e8db6d6e317a21183b3/src/timearray.jl#L437
    ts = TimeSeries.timestamp(ta)
    idx = searchsorted(ts, dt)
    # @show idx
    if length(idx) == 1
        return set_ta!(ta, idx[1], col_idx, value)
    end
    error("can't find $dt in TimeArray")
end

function set_ta!(ta::TimeArray, row_idx, key::Symbol, value)
    col_idx = findfirst(TimeSeries.colnames(ta) .== key)
    return set_ta!(ta, row_idx, col_idx, value)
end

set_ta!(ta::TimeArray, row_idx, key::String, value) = set_ta!(ta, row_idx, Symbol(key), value)


function to_df(reference_time::DateTime, ta::TimeArray, header, mat_map=identity)
    # TODO: include cases beyond Hour?

    ts = TimeSeries.timestamp(ta)
    tf_h = [h.value for h in Hour.(ts .- reference_time)]
    tf_h_next = tf_h .+ 1
    x = vec([(tf_h / 24)'; prevfloat.(tf_h_next / 24)'])
    _y = mat_map(values(ta))
    # y = vec([_y'; _y'])
    y = repeat(_y, inner=(2, 1))
    df = DataFrame([x y], header)
    return df
end
