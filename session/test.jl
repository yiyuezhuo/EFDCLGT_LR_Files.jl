
using EFDCLGT_LR_Files

WATER_ROOT = ENV["WATER_ROOT"]

efdc_inp_d = load(joinpath(WATER_ROOT, "efdc.inp"), efdc_inp)
wqini_inp_d = load(joinpath(WATER_ROOT, "wqini.inp"), wqini_inp)

buf = IOBuffer(); save(buf, efdc_inp_d); seek(buf, 0); println(read(buf, String))
buf = IOBuffer(); save(buf, wqini_inp_d); seek(buf, 0); println(read(buf, String))

open("efdc_test.inp", "w") do f
    save(f, efdc_inp_d)
end