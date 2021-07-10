module EFDCLGT_LR_Files

using Base: String
using DataFrames
export # file structs
    AbstractFile, efdc_inp, wqini_inp, WQWCRST_OUT, WQWCTS_OUT, cumu_struct_outflow_out, aser_inp,
    qbal_out, qser_inp, wqpsc_inp,
    # file methods
    load, save, align, time_align, value_align, align,
    # Runners
    Runner, SimulationTemplate, Replacer, Restarter,
    # Runner methods
    set_begin_day!, get_begin_day, set_sim_length!, get_sim_length, is_restarting, set_restarting!,
    add_begin_day!, copy_replacer, get_total_begin, get_total_length, convert_time,
    # Utilities
    create_simulation, get_exe_path

using CSV
using DataFrames
using JSON
using LightXML
using Dates
import TimeSeries # There're many methods which are conflicted with DataFrames
using TimeSeries: TimeArray
using Statistics

include("utils.jl")
include("io/io.jl")

include("abstract_runner.jl")
include("template.jl")
include("replacer.jl")
include("restarter.jl")

end # module
