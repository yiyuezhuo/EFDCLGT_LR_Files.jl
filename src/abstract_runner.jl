
abstract type Runner end
abstract type RunnerFunc <: Runner end;
abstract type RunnerStateful <: Runner end;

function master_map(r::Runner)
    error("master_map for $(typeof(r)) is undefined")
end

function Base.getindex(r::Runner, key)
    return master_map(r)[key]
end

function Base.setindex!(r::Runner, key, value)
    master_map(r)[key] = value
end

Base.keys(r::Runner) = keys(master_map(r))
Base.values(r::Runner) = values(master_map(r))
Base.isempty(r::Runner) = isempty(master_map(r))
Base.iterate(r::Runner, args...) = iterate(master_map(r), args...)

# https://discourse.julialang.org/t/broadcasting-structs-as-scalars/14310
# TODO: Research broadcast interface details:
# https://docs.julialang.org/en/v1/manual/interfaces/#man-interfaces-broadcasting
Base.broadcastable(runner::Runner) = Ref(runner) 
