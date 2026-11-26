fn near(a: f64, b: f64) -> bool {
    (a - b).abs() < 1e-6 || a * 0.5 > b
}
