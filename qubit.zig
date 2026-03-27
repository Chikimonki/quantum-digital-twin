// qubit.zig – Single qubit simulator with C ABI exports.
const std = @import("std");

pub const Complex = extern struct {
    re: f64,
    im: f64,
};

pub const State = extern struct {
    alpha: Complex,
    beta: Complex,
};

pub const Params = extern struct {
    omega: f64,
    delta: f64,
};

export fn qubit_init_state() State {
    return State{
        .alpha = Complex{ .re = 1.0, .im = 0.0 },
        .beta  = Complex{ .re = 0.0, .im = 0.0 },
    };
}

fn mul_real(z: Complex, r: f64) Complex {
    return Complex{ .re = z.re * r, .im = z.im * r };
}

fn add(a: Complex, b: Complex) Complex {
    return Complex{ .re = a.re + b.re, .im = a.im + b.im };
}

fn apply_h(alpha: Complex, beta: Complex, omega2: f64, delta2: f64) struct { dalpha: Complex, dbeta: Complex } {
    const term1 = add(mul_real(alpha, delta2), mul_real(beta, omega2));
    const term2 = add(mul_real(alpha, omega2), mul_real(beta, -delta2));
    const dalpha = Complex{ .re = term1.im, .im = -term1.re };
    const dbeta  = Complex{ .re = term2.im, .im = -term2.re };
    return .{ .dalpha = dalpha, .dbeta = dbeta };
}

export fn qubit_evolve(state: *State, params: *Params, dt: f64) void {
    const omega2 = params.omega / 2.0;
    const delta2 = params.delta / 2.0;

    const k1 = apply_h(state.alpha, state.beta, omega2, delta2);
    const a2 = add(state.alpha, mul_real(k1.dalpha, dt/2.0));
    const b2 = add(state.beta,  mul_real(k1.dbeta,  dt/2.0));
    const k2 = apply_h(a2, b2, omega2, delta2);

    const a3 = add(state.alpha, mul_real(k2.dalpha, dt/2.0));
    const b3 = add(state.beta,  mul_real(k2.dbeta,  dt/2.0));
    const k3 = apply_h(a3, b3, omega2, delta2);

    const a4 = add(state.alpha, mul_real(k3.dalpha, dt));
    const b4 = add(state.beta,  mul_real(k3.dbeta,  dt));
    const k4 = apply_h(a4, b4, omega2, delta2);

    const dalpha = add(add(add(mul_real(k1.dalpha, 1.0/6.0), mul_real(k2.dalpha, 1.0/3.0)), mul_real(k3.dalpha, 1.0/3.0)), mul_real(k4.dalpha, 1.0/6.0));
    const dbeta  = add(add(add(mul_real(k1.dbeta,  1.0/6.0), mul_real(k2.dbeta,  1.0/3.0)), mul_real(k3.dbeta,  1.0/3.0)), mul_real(k4.dbeta,  1.0/6.0));

    state.alpha = add(state.alpha, mul_real(dalpha, dt));
    state.beta  = add(state.beta,  mul_real(dbeta,  dt));
}

export fn qubit_prob_one(state: *State) f64 {
    return state.beta.re * state.beta.re + state.beta.im * state.beta.im;
}

export fn qubit_evolve_for(state: *State, params: *Params, dt: f64, total_time: f64) void {
    var t: f64 = 0.0;
    while (t < total_time - 1e-12) {
        const step = @min(dt, total_time - t);
        qubit_evolve(state, params, step);
        t += step;
    }
}

// ============================================
// Quantum Gate Operations
// ============================================

export fn qubit_gate_x(state: *State) void {
    const tmp = state.alpha;
    state.alpha = state.beta;
    state.beta = tmp;
}

export fn qubit_gate_z(state: *State) void {
    state.beta.re = -state.beta.re;
    state.beta.im = -state.beta.im;
}

export fn qubit_gate_h(state: *State) void {
    const inv_sqrt2: f64 = 0.7071067811865476;
    const new_alpha = Complex{
        .re = inv_sqrt2 * (state.alpha.re + state.beta.re),
        .im = inv_sqrt2 * (state.alpha.im + state.beta.im),
    };
    const new_beta = Complex{
        .re = inv_sqrt2 * (state.alpha.re - state.beta.re),
        .im = inv_sqrt2 * (state.alpha.im - state.beta.im),
    };
    state.alpha = new_alpha;
    state.beta = new_beta;
}

export fn qubit_gate_s(state: *State) void {
    const tmp_re = state.beta.re;
    state.beta.re = -state.beta.im;
    state.beta.im = tmp_re;
}

export fn qubit_gate_t(state: *State) void {
    const cos_pi8: f64 = 0.9238795325112867;
    const sin_pi8: f64 = 0.3826834323650898;
    const new_re = cos_pi8 * state.beta.re - sin_pi8 * state.beta.im;
    const new_im = sin_pi8 * state.beta.re + cos_pi8 * state.beta.im;
    state.beta.re = new_re;
    state.beta.im = new_im;
}

export fn qubit_rotate_x(state: *State, theta: f64) void {
    const cos_t = @cos(theta / 2.0);
    const sin_t = @sin(theta / 2.0);
    const new_alpha = Complex{
        .re = cos_t * state.alpha.re + sin_t * state.beta.im,
        .im = cos_t * state.alpha.im - sin_t * state.beta.re,
    };
    const new_beta = Complex{
        .re = sin_t * state.alpha.im + cos_t * state.beta.re,
        .im = -sin_t * state.alpha.re + cos_t * state.beta.im,
    };
    state.alpha = new_alpha;
    state.beta = new_beta;
}

export fn qubit_prob_zero(state: *State) f64 {
    return state.alpha.re * state.alpha.re + state.alpha.im * state.alpha.im;
}

export fn qubit_bloch_x(state: *State) f64 {
    return 2.0 * (state.alpha.re * state.beta.re + state.alpha.im * state.beta.im);
}

export fn qubit_bloch_y(state: *State) f64 {
    return 2.0 * (state.alpha.re * state.beta.im - state.alpha.im * state.beta.re);
}

export fn qubit_bloch_z(state: *State) f64 {
    const p0 = state.alpha.re * state.alpha.re + state.alpha.im * state.alpha.im;
    const p1 = state.beta.re * state.beta.re + state.beta.im * state.beta.im;
    return p0 - p1;
}

export fn qubit_apply_noise(state: *State, t1_decay: f64) void {
    const decay = @exp(-t1_decay);
    state.beta.re *= decay;
    state.beta.im *= decay;
    const norm = @sqrt(state.alpha.re * state.alpha.re +
                       state.alpha.im * state.alpha.im +
                       state.beta.re * state.beta.re +
                       state.beta.im * state.beta.im);
    if (norm > 1e-12) {
        state.alpha.re /= norm;
        state.alpha.im /= norm;
        state.beta.re /= norm;
        state.beta.im /= norm;
    }
}

export fn qubit_run_circuit(state: *State, gates: [*]const u8, num_gates: usize) void {
    for (0..num_gates) |i| {
        switch (gates[i]) {
            0 => qubit_gate_x(state),
            1 => qubit_gate_z(state),
            2 => qubit_gate_h(state),
            3 => qubit_gate_s(state),
            4 => qubit_gate_t(state),
            else => {},
        }
    }
}
