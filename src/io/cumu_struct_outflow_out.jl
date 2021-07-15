
struct cumu_struct_outflow_out <: PureDataFrameFile
    df::DataFrame
end

name(::Type{cumu_struct_outflow_out}) = "cumu_struct_outflow.out"
time_key(::Type{cumu_struct_outflow_out}) = :Jday

function value_align(::Type{cumu_struct_outflow_out}, ta::DateDataFrame)
    # lead_ta = lead(ta)
    diff_ta = diff(ta[!, names(ta)[2:end]]; padding=true) |> lead
    # return hcat(lead_ta["Jday"], diff_ta)
    return diff_ta
end

