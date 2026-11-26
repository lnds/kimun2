// What `mi` reads differently from km it takes from `hal` and `cycom`:
// a real is one operand, and `&&` in a reference type is no decision.

pub fn half(x: f64) -> f64 {
    x * 0.5
}

pub fn first(words: &[&str]) -> Option<&&str> {
    words.first()
}
