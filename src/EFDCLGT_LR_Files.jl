module EFDCLGT_LR_Files

using Base: String
using DataFrames
export efdc_inp, wqini_inp, load, save, create_simulation, get_exe_path,
    SimulationTemplate, Replacer, Restarter,
    efdc_inp, wqini_inp, WQWCRST_OUT,
    set_begin_day!, get_begin_day, set_sim_length!, get_sim_length, is_restarting, set_restarting!

using CSV
using DataFrames
using JSON
using LightXML
using Dates

abstract type AbstractFile end

function load(path, ::Type{<:AbstractFile})
    open(path, "w") do f
        return load(d, f)
    end
end

function load(io::IO, ::Type{<:AbstractFile})
    error("Unsupporedted load format $f")
end

function save(path, d::AbstractFile)
    open(path, "w") do f
        save(f, d)
    end
end

function save(io::IO, d::AbstractFile)
    error("Unsupporedted save format $f")
end

function save(io::IO, d::Vector{String})
    write(io, join(d, "\n"))
    write(io, "\n")
end

function save(io::IO, d::DataFrame; header=false)
    CSV.write(io, d, append=true, header=header, delim=" ")
end

name(typ::Type{<:AbstractFile}) = error("Name of $typ is undefined")

include("io/master_input.jl")
include("io/efdc_inp_io.jl")
include("io/wqini_inp_WQWCRST_OUT_io.jl")

abstract type Runner end
abstract type RunnerFunc <: Runner end;
abstract type RunnerStateful <: Runner end;

include("template.jl")
include("replacer.jl")
include("restarter.jl")

using .efdc_inp_io
using .wqini_inp_WQWCRST_OUT_io

# greet() = print("Hello World!")

end # module
