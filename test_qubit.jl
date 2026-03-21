const lib = "./libqubit.so"

struct Complex
    re::Float64
    im::Float64
end

struct State
    alpha::Complex
    beta::Complex
end

struct Params
    omega::Float64
    delta::Float64
end

# Define functions that take Ref (mutable containers) and pass them directly to ccall.
# The conversion from Ref to Ptr happens automatically inside ccall.
init_state() = ccall((:qubit_init_state, lib), State, ())

evolve(state::Ref{State}, params::Ref{Params}, dt::Float64) = 
    ccall((:qubit_evolve, lib), Cvoid, (Ptr{State}, Ptr{Params}, Float64), state, params, dt)

prob_one(state::Ref{State}) = 
    ccall((:qubit_prob_one, lib), Float64, (Ptr{State},), state)

evolve_for(state::Ref{State}, params::Ref{Params}, dt::Float64, total_time::Float64) = 
    ccall((:qubit_evolve_for, lib), Cvoid, (Ptr{State}, Ptr{Params}, Float64, Float64), state, params, dt, total_time)

# Create mutable references to hold state and parameters
state_ref = Ref{State}(init_state())
params_ref = Ref{Params}(Params(10.0, 0.0))

# Evolve for 0.2 seconds
evolve_for(state_ref, params_ref, 0.001, 0.2)

# Get probability
prob = prob_one(state_ref)
println("Probability of |1> after 0.2s: ", round(prob, digits=4))
