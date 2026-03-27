package main

import (
    "encoding/json"
    "fmt"
    "log"
    "math"
    "net/http"
    "os"
    "strconv"
)

func enableCORS(w http.ResponseWriter) {
    w.Header().Set("Access-Control-Allow-Origin", "*")
    w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

// Simulate Rabi oscillation in pure Go (for cloud deployment)
func simulateRabi(omega, delta, totalTime, dt float64) map[string]interface{} {
    // Simple Euler integration of Schrodinger equation
    alphaRe, alphaIm := 1.0, 0.0
    betaRe, betaIm := 0.0, 0.0

    omega2 := omega / 2.0
    delta2 := delta / 2.0
    steps := int(totalTime / dt)

    trajectory := make([]float64, 0, steps/10)

    for i := 0; i < steps; i++ {
        // H*psi terms
        t1Re := delta2*alphaRe + omega2*betaRe
        t1Im := delta2*alphaIm + omega2*betaIm
        t2Re := omega2*alphaRe - delta2*betaRe
        t2Im := omega2*alphaIm - delta2*betaIm

        // Multiply by -i*dt
        alphaRe += t1Im * dt
        alphaIm += -t1Re * dt
        betaRe += t2Im * dt
        betaIm += -t2Re * dt

        // Normalize
        norm := math.Sqrt(alphaRe*alphaRe + alphaIm*alphaIm + betaRe*betaRe + betaIm*betaIm)
        alphaRe /= norm
        alphaIm /= norm
        betaRe /= norm
        betaIm /= norm

        // Record trajectory (every 10 steps)
        if i%10 == 0 {
            prob1 := betaRe*betaRe + betaIm*betaIm
            trajectory = append(trajectory, math.Round(prob1*10000)/10000)
        }
    }

    prob1 := betaRe*betaRe + betaIm*betaIm
    prob0 := alphaRe*alphaRe + alphaIm*alphaIm

    // Bloch sphere coordinates
    blochX := 2.0 * (alphaRe*betaRe + alphaIm*betaIm)
    blochY := 2.0 * (alphaRe*betaIm - alphaIm*betaRe)
    blochZ := prob0 - prob1

    return map[string]interface{}{
        "omega":      omega,
        "delta":      delta,
        "total_time": totalTime,
        "dt":         dt,
        "steps":      steps,
        "prob_0":     math.Round(prob0*10000) / 10000,
        "prob_1":     math.Round(prob1*10000) / 10000,
        "bloch":      map[string]float64{"x": blochX, "y": blochY, "z": blochZ},
        "trajectory": trajectory,
        "simulator":  "go-euler",
    }
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    enableCORS(w)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "service": "quantum-digital-twin",
        "status":  "healthy",
    })
}

func simulateHandler(w http.ResponseWriter, r *http.Request) {
    enableCORS(w)
    if r.Method == "OPTIONS" {
        w.WriteHeader(200)
        return
    }
    w.Header().Set("Content-Type", "application/json")

    // Parse parameters from query string
    omega, _ := strconv.ParseFloat(r.URL.Query().Get("omega"), 64)
    delta, _ := strconv.ParseFloat(r.URL.Query().Get("delta"), 64)
    totalTime, _ := strconv.ParseFloat(r.URL.Query().Get("time"), 64)

    if omega == 0 {
        omega = 10.0
    }
    if totalTime == 0 {
        totalTime = 0.2
    }

    result := simulateRabi(omega, delta, totalTime, 0.001)
    json.NewEncoder(w).Encode(result)
}

func gatesHandler(w http.ResponseWriter, r *http.Request) {
    enableCORS(w)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "available_gates": []map[string]string{
            {"id": "X", "name": "Pauli-X (NOT)", "description": "Bit flip gate"},
            {"id": "Z", "name": "Pauli-Z", "description": "Phase flip gate"},
            {"id": "H", "name": "Hadamard", "description": "Creates superposition"},
            {"id": "S", "name": "Phase (S)", "description": "90-degree phase rotation"},
            {"id": "T", "name": "T gate", "description": "45-degree phase rotation"},
        },
    })
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
    enableCORS(w)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "service":     "Quantum Digital Twin API",
        "version":     "2.0",
        "description": "Single-qubit quantum simulator with ML surrogate",
        "stack":       []string{"Zig", "Julia", "LuaJIT", "Go"},
        "endpoints": map[string]string{
            "GET /health":              "Service health check",
            "GET /simulate?omega=&delta=&time=": "Run quantum simulation",
            "GET /gates":               "List available quantum gates",
        },
    })
}

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    http.HandleFunc("/", rootHandler)
    http.HandleFunc("/health", healthHandler)
    http.HandleFunc("/simulate", simulateHandler)
    http.HandleFunc("/gates", gatesHandler)

    fmt.Println("═══════════════════════════════════════")
    fmt.Println("  Quantum Digital Twin API")
    fmt.Printf("  Port: %s\n", port)
    fmt.Println("═══════════════════════════════════════")

    log.Fatal(http.ListenAndServe(":"+port, nil))
}
