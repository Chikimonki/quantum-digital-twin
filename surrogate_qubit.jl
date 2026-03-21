using Flux
using Plots
using BenchmarkTools
using Zygote
using Optimisers

# Load the Zig library
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

init_state() = ccall((:qubit_init_state, lib), State, ())
evolve(state::Ref{State}, params::Ref{Params}, dt::Float64) =
    ccall((:qubit_evolve, lib), Cvoid, (Ptr{State}, Ptr{Params}, Float64), state, params, dt)
prob_one(state::Ref{State}) =
    ccall((:qubit_prob_one, lib), Float64, (Ptr{State},), state)
evolve_for(state::Ref{State}, params::Ref{Params}, dt::Float64, total_time::Float64) =
    ccall((:qubit_evolve_for, lib), Cvoid, (Ptr{State}, Ptr{Params}, Float64, Float64), state, params, dt, total_time)

# --- 1. Generate training data (Float64 simulation, convert to Float32) ---
println("Generating training data (50×50 grid)...")
omegas_f64 = range(0.0, 20.0, length=50)
deltas_f64 = range(-10.0, 10.0, length=50)
dt_sim = 0.001
total_time = 0.2

inputs = Vector{Float32}[]
targets = Float32[]

for omega in omegas_f64
    for delta in deltas_f64
        state_ref = Ref{State}(init_state())
        params_ref = Ref{Params}(Params(omega, delta))
        evolve_for(state_ref, params_ref, dt_sim, total_time)
        prob = Float32(prob_one(state_ref))
        push!(inputs, [Float32(omega), Float32(delta)])
        push!(targets, prob)
    end
end

X = hcat(inputs...)   # 2 x N
y = reshape(targets, 1, :)

# Split into train/validation (80/20)
n = size(X, 2)
train_idx = 1:floor(Int, 0.8n)
val_idx = floor(Int, 0.8n)+1:n
X_train, X_val = X[:, train_idx], X[:, val_idx]
y_train, y_val = y[:, train_idx], y[:, val_idx]

# --- 2. Build neural network (larger capacity) ---
model = Chain(
    Dense(2, 128, relu),
    Dense(128, 128, relu),
    Dense(128, 64, relu),
    Dense(64, 1)
)

loss(m, x, y) = Flux.mse(m(x), y)

# --- 3. Train using modern Flux API ---
println("Training surrogate model...")
opt = Flux.setup(Adam(0.001f0), model)
data = [(X_train, y_train)]
epochs = 600
for epoch in 1:epochs
    Flux.train!(model, data, opt) do m, x, y
        loss(m, x, y)
    end
    if epoch % 100 == 0
        train_loss = loss(model, X_train, y_train)
        val_loss = loss(model, X_val, y_val)
        println("Epoch $epoch, train loss = $train_loss, val loss = $val_loss")
    end
end

# --- 4. Evaluation on a test point ---
println("\nEvaluation on a random point (omega=12, delta=5):")
test_omega_f64 = 12.0
test_delta_f64 = 5.0
state_ref = Ref{State}(init_state())
params_ref = Ref{Params}(Params(test_omega_f64, test_delta_f64))
evolve_for(state_ref, params_ref, dt_sim, total_time)
true_prob = Float32(prob_one(state_ref))
pred_prob = model([Float32(test_omega_f64), Float32(test_delta_f64)])[1]
println("True probability: ", round(true_prob, digits=4))
println("Surrogate prediction: ", round(pred_prob, digits=4))
println("Error: ", round(abs(true_prob - pred_prob), digits=4))

# --- 5. Optimization using surrogate (maximize probability) ---
println("\nOptimizing parameters to maximize probability using surrogate...")

function optimize_parameters(model, x0, steps=200, lr=0.01f0)
    function loss_opt(x)
        -model(x)[1]   # negative probability
    end
    opt_state = Optimisers.setup(Adam(lr), x0)
    x = copy(x0)
    for i in 1:steps
        g = Zygote.gradient(loss_opt, x)[1]
        opt_state, x = Optimisers.update(opt_state, x, g)
        if i % 50 == 0
            println("Step $i, prob = ", -loss_opt(x))
        end
    end
    return x
end

x0 = Float32[10.0, 0.0]
x_opt = optimize_parameters(model, x0)
best_omega_f32, best_delta_f32 = x_opt
best_omega_f64 = Float64(best_omega_f32)
best_delta_f64 = Float64(best_delta_f32)

println("\nOptimized parameters: omega = ", round(best_omega_f64, digits=2), ", delta = ", round(best_delta_f64, digits=2))
println("Surrogate-predicted probability: ", round(-model(x_opt)[1], digits=4))

# Verify with real simulator
state_ref = Ref{State}(init_state())
params_ref = Ref{Params}(Params(best_omega_f64, best_delta_f64))
evolve_for(state_ref, params_ref, dt_sim, total_time)
true_best = Float32(prob_one(state_ref))
println("True probability at optimized point: ", round(true_best, digits=4))
println("Difference: ", round(abs(true_best - (-model(x_opt)[1])), digits=4))

# --- 6. Performance comparison ---
println("\nPerformance comparison (1000 evaluations):")
function simulate_bulk(n)
    for i in 1:n
        state_ref = Ref{State}(init_state())
        omega = rand() * 20.0
        delta = (rand() * 20.0) - 10.0
        params_ref = Ref{Params}(Params(omega, delta))
        evolve_for(state_ref, params_ref, dt_sim, total_time)
        prob_one(state_ref)
    end
end

function surrogate_bulk(n)
    X_bulk = hcat([Float32[rand()*20.0, (rand()*20.0)-10.0] for _ in 1:n]...)
    model(X_bulk)
end

t_sim = @belapsed simulate_bulk(1000)
t_surr = @belapsed surrogate_bulk(1000)
println("Full simulation time: ", round(t_sim, digits=4), " s")
println("Surrogate model time: ", round(t_surr, digits=4), " s")
println("Speedup: ", round(t_sim / t_surr, digits=1), "x")

# --- 7. Visualize the surrogate ---
println("\nGenerating heatmap...")
ω_grid = Float32.(range(0, 20, length=100))
δ_grid = Float32.(range(-10, 10, length=100))
Z = [model([ω, δ])[1] for ω in ω_grid, δ in δ_grid]
heatmap(ω_grid, δ_grid, Z, xlabel="ω (Rabi freq)", ylabel="Δ (detuning)", title="Surrogate model: Probability of |1>", c=:viridis)
savefig("surrogate_map.png")
println("Saved heatmap to surrogate_map.png")

println("\nDone.")
