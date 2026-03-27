local ffi = require("ffi")

ffi.cdef[[
    typedef struct { double re, im; } Complex;
    typedef struct { Complex alpha, beta; } State;
    typedef struct { double omega, delta; } Params;

    State qubit_init_state();
    void qubit_evolve(State* state, Params* params, double dt);
    double qubit_prob_one(State* state);
    double qubit_prob_zero(State* state);
    void qubit_gate_x(State* state);
    void qubit_gate_z(State* state);
    void qubit_gate_h(State* state);
    void qubit_gate_s(State* state);
    void qubit_gate_t(State* state);
    void qubit_rotate_x(State* state, double theta);
    double qubit_bloch_x(State* state);
    double qubit_bloch_y(State* state);
    double qubit_bloch_z(State* state);
    void qubit_apply_noise(State* state, double t1_decay);
    void qubit_run_circuit(State* state, const uint8_t* gates, size_t num_gates);
]]

local lib = ffi.load("./libqubit.so")

print("═══════════════════════════════════════")
print("  Quantum Digital Twin v2.0")
print("  Gate Operations Test Suite")
print("═══════════════════════════════════════")
print("")

-- Test 1: Initial state |0>
print("Test 1: Initial state")
local state = lib.qubit_init_state()
print(string.format("  |0> probability: %.4f (expect 1.0)", lib.qubit_prob_zero(state)))
print(string.format("  |1> probability: %.4f (expect 0.0)", lib.qubit_prob_one(state)))
print(string.format("  Bloch Z: %.4f (expect 1.0 = north pole)", lib.qubit_bloch_z(state)))
print("")

-- Test 2: X gate (bit flip)
print("Test 2: Pauli-X gate (NOT)")
state = lib.qubit_init_state()
lib.qubit_gate_x(state)
print(string.format("  After X: |0>=%.4f, |1>=%.4f", lib.qubit_prob_zero(state), lib.qubit_prob_one(state)))
print(string.format("  Bloch Z: %.4f (expect -1.0 = south pole)", lib.qubit_bloch_z(state)))
print("")

-- Test 3: Hadamard gate (superposition)
print("Test 3: Hadamard gate")
state = lib.qubit_init_state()
lib.qubit_gate_h(state)
print(string.format("  After H: |0>=%.4f, |1>=%.4f (expect 0.5, 0.5)", lib.qubit_prob_zero(state), lib.qubit_prob_one(state)))
print(string.format("  Bloch X: %.4f (expect 1.0 = equator)", lib.qubit_bloch_x(state)))
print("")

-- Test 4: H then X then H = Z
print("Test 4: Circuit H-X-H = Z")
state = lib.qubit_init_state()
lib.qubit_gate_h(state)
lib.qubit_gate_x(state)
lib.qubit_gate_h(state)
print(string.format("  After HXH: |0>=%.4f, |1>=%.4f", lib.qubit_prob_zero(state), lib.qubit_prob_one(state)))
print(string.format("  Bloch Z: %.4f (expect 1.0)", lib.qubit_bloch_z(state)))
print("")

-- Test 5: Run circuit using gate sequence
print("Test 5: Circuit runner [H, X, H]")
state = lib.qubit_init_state()
local gates = ffi.new("uint8_t[3]", {2, 0, 2})
lib.qubit_run_circuit(state, gates, 3)
print(string.format("  After circuit: |0>=%.4f, |1>=%.4f", lib.qubit_prob_zero(state), lib.qubit_prob_one(state)))
print("")

-- Test 6: Noise model
print("Test 6: Noise (T1 decay)")
state = lib.qubit_init_state()
lib.qubit_gate_x(state)
print(string.format("  Before noise: |1>=%.4f", lib.qubit_prob_one(state)))
lib.qubit_apply_noise(state, 0.5)
print(string.format("  After noise (0.5 decay): |1>=%.4f (should decrease)", lib.qubit_prob_one(state)))
lib.qubit_apply_noise(state, 2.0)
print(string.format("  After heavy noise (2.0 decay): |1>=%.4f (near zero)", lib.qubit_prob_one(state)))
print("")

-- Test 7: Bloch sphere trajectory
print("Test 7: Bloch sphere trajectory (X rotation)")
state = lib.qubit_init_state()
print("  Rotating around X axis:")
for i = 0, 8 do
    local theta = i * math.pi / 4
    state = lib.qubit_init_state()
    lib.qubit_rotate_x(state, theta)
    print(string.format("    theta=%.2f: X=%.3f Y=%.3f Z=%.3f",
        theta, lib.qubit_bloch_x(state), lib.qubit_bloch_y(state), lib.qubit_bloch_z(state)))
end

print("")
print("═══════════════════════════════════════")
print("  All tests complete!")
print("═══════════════════════════════════════")
