
struct qbal_out <: AbstractFile
    broken_header::String
    df::DataFrame
end

function load(io::IO, ::Type{qbal_out})
    qbac_header_text_broken = "                                                 jday elev(m) qin(million-m3)qou(million-m3)  qctlo(million-m3)  qin(m) qou(m) qctlo(m) rain(m) eva(m)\n"
    qbac_header_text = "jday elev(m) qin(million-m3) qou(million-m3)  qctlo(million-m3)  qin(m) qou(m) qctlo(m) rain(m) eva(m)"

    broken_header = (take(eachline(io), 1) |> collect)[1]
    if broken_header != qbac_header_text_broken
        @warn "Expected $qbac_header_text_broken, got $broken_header."
    end

    qbac_header = split(qbac_header_text)

    df = CSV.File(io, header=true, delim=" ", ignorerepeated=true)
    rename!(df, qbac_header)
    
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
    diff_ta = TimeArrays.diff(ta["qctlo(million-m3)"], padding=true) |> lead
    return hcat(lead_ta["jday"], lead_ta["elev(m)"], diff_ta)
end
