
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

function Base.append!(d::cumu_struct_outflow_out, d2::cumu_struct_outflow_out)
    df = d.df
    df2 = deepcopy(d2.df)
    tk =  string(time_key(cumu_struct_outflow_out))
    @assert df[end, tk] <= df2[begin, tk]
    for n in names(df2)
        if string(n) != tk
            df2[!, n] .+= df[end, n]
        end
    end
    append!(df, df2)
end
