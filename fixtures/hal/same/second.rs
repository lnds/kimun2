fn total(xs: &[u32]) -> u32 {
    let mut t = 0;
    let mut i = 0;
    while i < xs.len() {
        t += xs[i];
        i += 1;
    }
    t
}
