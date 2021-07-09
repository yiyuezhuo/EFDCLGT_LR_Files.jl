
struct cumu_struct_outflow_out <: PureDataFrameFile
    df::DataFrame
end

name(::Type{cumu_struct_outflow_out}) = "cumu_struct_outflow.out"
time_key(::Type{cumu_struct_outflow_out}) = :Jday

function value_align(::Type{cumu_struct_outflow_out}, ta::TimeArray)
    lead_ta = TimeSeries.lead(ta)
    diff_ta = TimeSeries.diff(ta[TimeSeries.colnames(ta)[2:end]], padding=true) |> TimeSeries.lead
    return hcat(lead_ta["Jday"], diff_ta)
end

