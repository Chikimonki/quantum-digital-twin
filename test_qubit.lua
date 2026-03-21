local ffi = require("ffi")

ffi.cdef[[
    typedef struct { double re, im; } Complex;
    typedef struct { Complex alpha, beta; } State;
    typedef struct { double omega, delta; } Params;

    State qubit_init_state();
    void qubit_evolve(State* state, Params* params, double dt);
    double qubit_prob_one(State* state);
    void qubit_evolve_for(State* state, Params* params, double dt, double total_time);
]]
local ffi = require("ffi")

local lib = ffi.load("./libqubit.so")

-- Initialize
local state = lib.qubit_init_state()
local params = ffi.new("Params", { omega = 10.0, delta = 0.0 })

-- Evolve for a total of 0.2 seconds with dt = 0.001
lib.qubit_evolve_for(state, params, 0.001, 0.2)

-- Probability of |1>
local prob = lib.qubit_prob_one(state)
print(string.format("Probability of |1> after 0.2s: %.4f", prob))

-- Expect around 0.5 for omega=10, delta=0 (Rabi flop half-period ≈ 0.314s, so 0.2s gives ~0.5)
