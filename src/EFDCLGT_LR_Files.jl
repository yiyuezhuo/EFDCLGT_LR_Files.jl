module EFDCLGT_LR_Files

using Base: String
using DataFrames
export efdc_inp, wqini_inp, load, save, create_simulation, setup_restart, SimulationTemplate

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

function save(io::IO, d::DataFrame; writeheader=false)
    CSV.write(io, d, append=true, writeheader=writeheader, delim=" ")
end


include("io/master_input.jl")
include("io/efdc_inp_io.jl")
include("io/wqini_inp_io.jl")
include("template.jl")

using .efdc_inp_io
using .wqini_inp_io

# greet() = print("Hello World!")

end # module
