

include("common.jl")
include("master_input.jl")

include("efdc_inp.jl")  # master control
include("wqini_inp_WQWCRST_OUT.jl")  # initial cell concentration
include("WQWCTS_OUT.jl")  # cell concentration time series 
include("cumu_struct_outflow_out.jl")  # overflow points flow
include("qbal_out.jl")  # cumu general summary
include("aser_inp.jl")  # air condition and misc etc
include("qser_inp.jl")  # out/inflow flow
include("wqpsc_inp.jl")  # inflow concentration