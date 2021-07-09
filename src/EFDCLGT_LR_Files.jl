module EFDCLGT_LR_Files

using Base: String
using DataFrames
export # file structs
    AbstractFile, efdc_inp, wqini_inp, WQWCRST_OUT, WQWCTS_OUT, cumu_struct_outflow_out, aser_inp,
    qbal_out,
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

include("utils.jl")
include("io/io.jl")

abstract type Runner end
abstract type RunnerFunc <: Runner end;
abstract type RunnerStateful <: Runner end;

# https://discourse.julialang.org/t/broadcasting-structs-as-scalars/14310
# TODO: Research broadcast interface details:
# https://docs.julialang.org/en/v1/manual/interfaces/#man-interfaces-broadcasting
Base.broadcastable(runner::Runner) = Ref(runner) 

include("template.jl")
include("replacer.jl")
include("restarter.jl")

end # module
