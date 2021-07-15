
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

function to_df(reference_time::DateTime, ta::DateDataFrame, header, arr_map=identity)
    # TODO: include cases beyond Hour?

    ts = timestamp(ta)
    tf_h = [h.value for h in Hour.(ts .- reference_time)]
    tf_h_next = tf_h .+ 1
    x = vec([(tf_h / 24)'; prevfloat.(tf_h_next / 24)'])
    _y_vec = arr_map.(eachcol(ta))
    y_vec = repeat.(_y_vec, inner=2)
    d = [x]
    append!(d, y_vec)
    df = DataFrame(d, header)
    return df
end

# These functions just use Julia default function at this time, but this may change in future.

function efdc_lp_tempdir()
    return tempdir()
end

function efdc_lp_tempname()
    return tempname()
end

function is_efdc_lp_tempname(p)
    # This may delete some files wrongly. however, they're "temporary" files...
    return startswith(p, "jl_")
end

function efdc_lp_cleanup()
    root = efdc_lp_tempdir()
    name_vec = filter(is_efdc_lp_tempname, readdir(root))

    @info "Ready to delete $(length(name_vec)) files, first is $(joinpath(root, name_vec[1]))"

    ProgressMeter.@showprogress for name in name_vec
        p = joinpath(root, name)
        rm(p, recursive=true)
    end
end
