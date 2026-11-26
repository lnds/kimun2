fn fallback(x: Option<u32>) -> u32 {
    x.unwrap_or_else(|| 7)
}
