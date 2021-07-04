
# This file is not included in main module and is expected to be used by 
# `include(joinpath(dirname(pathof(EFDCLGT_LR_Files)), "dev_tools.jl"))`

WATER_ROOT = ENV["WATER_ROOT"]
efdc_inp_d = load(efdc_inp, joinpath(WATER_ROOT, "efdc.inp"))
wqini_inp_d = load(wqini_inp, joinpath(WATER_ROOT, "wqini.inp"))
