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

// Compute H*psi for given (alpha, beta) and parameters.
// Returns (dalpha/dt, dbeta/dt) as a tuple.
fn apply_h(alpha: Complex, beta: Complex, omega2: f64, delta2: f64) struct { dalpha: Complex, dbeta: Complex } {
    // dα/dt = -i ( (Δ/2) α + (Ω/2) β )
    // dβ/dt = -i ( (Ω/2) α - (Δ/2) β )
    const term1 = add(mul_real(alpha, delta2), mul_real(beta, omega2));
    const term2 = add(mul_real(alpha, omega2), mul_real(beta, -delta2));
    // Multiply by -i: (a+ib)*(-i) = b - i a
    const dalpha = Complex{ .re = term1.im, .im = -term1.re };
    const dbeta  = Complex{ .re = term2.im, .im = -term2.re };
    return .{ .dalpha = dalpha, .dbeta = dbeta };
}

export fn qubit_evolve(state: *State, params: *Params, dt: f64) void {
    const omega2 = params.omega / 2.0;
    const delta2 = params.delta / 2.0;

    // RK4
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
