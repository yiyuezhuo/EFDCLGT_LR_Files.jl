
struct qbal_out <: AbstractFile
    broken_header::String
    df::DataFrame
end

function load(io::IO, ::Type{qbal_out})
    qbal_header_text_broken = "                                                 jday elev(m) qin(million-m3)qou(million-m3)  qctlo(million-m3)  qin(m) qou(m) qctlo(m) rain(m) eva(m)"
    qbal_header_text = "jday elev(m) qin(million-m3) qou(million-m3)  qctlo(million-m3)  qin(m) qou(m) qctlo(m) rain(m) eva(m)"

    broken_header = (Iterators.take(eachline(io), 1) |> collect)[1]
    if broken_header != qbal_header_text_broken
        @warn "Expected: $qbal_header_text_broken, got: $broken_header."
    end

    qbal_header = split(qbal_header_text)

    df = CSV.File(io, header=false, delim=" ", ignorerepeated=true) |> DataFrame
    rename!(df, qbal_header)
    
    return qbal_out(broken_header, df)
end

function save(io::IO, d::qbal_out)
    write(io, d.broken_header)
    write(io, "\n")
    write(io, d.df)
end

name(::Type{qbal_out}) = "qbal.out"
time_key(::Type{qbal_out}) = :jday

function value_align(::Type{qbal_out}, ta::TimeArray)
    lead_ta = TimeSeries.lead(ta)
    diff_ta = - TimeSeries.lead(TimeSeries.diff(ta["qctlo(million-m3)"], padding=true)) .* 1_000_000 # million-m3 -> m3
    TimeSeries.rename!(diff_ta, [:qctlo])
    # return diff_ta
    return hcat(lead_ta["elev(m)"], diff_ta)
end

function align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, d::qbal_out)
    ta = time_align(dt, FT, DT, d.df, time_key(qbal_out))
    return value_align(qbal_out, ta)
end
