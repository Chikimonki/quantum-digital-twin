# quantum-digital-twin
Using the latest Polyglot method I took an idea and turned it into a reproducible, modular, and faster than the conventional approach. It’s a paradigm shift in how quickly one can prototype quantum‑AI workflows.
# Quantum Digital Twin with Zig + Julia + LuaJIT

This project demonstrates a **full‑stack digital twin** for a single qubit under Rabi drive. 

It uses:

- **Zig** – high‑performance qubit simulator (compiled to a shared library).
- **LuaJIT** – lightweight FFI for quick testing and orchestration.
- **Julia** – surrogate model training (Flux) and AI‑driven optimization.

The surrogate achieves ~7× speedup (inference vs. simulation) and accurately predicts the final state probability, enabling rapid design space exploration.

## Requirements

- Zig (0.13 or later)
- Julia (1.9 or later) with packages: Flux, Plots, BenchmarkTools, Zygote, Optimisers
- LuaJIT (optional, for testing)
