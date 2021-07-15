
struct WQWCTS_OUT <: PureDataFrameFile
    df::DataFrame
end

name(::Type{WQWCTS_OUT}) = "WQWCTS.OUT"
time_key(::Type{WQWCTS_OUT}) = :TIME

#=
function load(io::IO, ::Type{WQWCTS_OUT})
    return CSV.File(io, header=true, delim=" ", ignorerepeated=true) |> DataFrame |> WQWCTS_OUT
end

function save(io::IO, d::WQWCTS_OUT)
    # However, we don't need to overwrite `WQWCTS.OUT` at this time.
    save(io, d.df, header=true)
end
=#

function value_align(::Type{WQWCTS_OUT}, ta::DateDataFrame)
    ta = ta[!, names(ta)[5:end]] # remove I, J, K, TIME columns
    ta = moving(mean, ta, 2, padding=true) |> lead # average discrete observation to get period estimation
    return ta
end

function align(dt::DateTime, FT::Type{<:Period}, DT::Type{<:Union{DateTime, <:Period}}, d::WQWCTS_OUT)
    rd = Dict{Tuple{Int, Int, Int}, DateDataFrame}()
    for (k, df) in pairs(groupby(d.df, [:I, :J, :K]))
        ta = time_align(dt, FT, DT, df, time_key(WQWCTS_OUT))
        rd[k.I, k.J, k.K] = value_align(WQWCTS_OUT, ta)
    end
    return rd
end
