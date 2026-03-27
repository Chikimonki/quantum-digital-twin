⚛️ QUANTUM SIMULATOR IS LIVE!

https://storage.googleapis.com/groq-chat-api-quantum-twin-ui/index.html

Video: https://youtu.be/vgfek9W-YKM
# quantum-digital-twin
Using the latest Polyglot method I took an idea and turned it into a reproducible, modular, and faster than the conventional approach quantum digital twin. It’s a paradigm shift in how quickly one can prototype quantum‑AI workflows.
# Quantum Digital Twin with Zig + Julia + LuaJIT

This project demonstrates a **full‑stack digital twin** for a single qubit under Rabi drive. 

It uses:

- **Zig** – high‑performance qubit simulator (compiled to a shared library).
- **LuaJIT** – lightweight FFI for quick testing and orchestration.
- **Julia** – surrogate model training (Flux) and AI‑driven optimization.

The surrogate achieves ~7× speedup (inference vs. simulation) and accurately predicts the final state probability, enabling rapid design space exploration.

Here's a Cheat Sheet:

SLIDER EFFECTS:
═══════════════════════════════════════

Omega (ω) = How HARD you push the qubit
  ↑ High omega = Fast oscillations
  ↓ Low omega  = Slow, gentle changes

Delta (Δ) = How "off-tune" the drive is
  = 0: Perfect resonance (maximum effect)
  ≠ 0: Detuned (qubit resists changing)

Time = How LONG you apply the drive
  Short: Qubit barely moves
  Long:  Multiple oscillations

GATES:
═══════════════════════════════════════

X = Flip the qubit (|0⟩ → |1⟩)
H = Superposition (50/50)
Z = Phase flip (invisible but real!)
S = Quarter turn
T = Eighth turn (the "magic" gate)


## Requirements

- Zig (0.13 or later)
- Julia (1.9 or later) with packages: Flux, Plots, BenchmarkTools, Zygote, Optimisers
- LuaJIT (optional, for testing)
