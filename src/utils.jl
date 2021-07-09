
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
