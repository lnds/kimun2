pub fn from_iter<P: AsRef<str>, I: IntoIterator<Item = P>>(
    paths: I,
) -> usize {
    let mut n = 0;
    for _ in paths.into_iter() {
        n += 1;
    }
    n
}

pub fn r#async(ready: bool) -> u8 {
    if ready { 1 } else { 0 }
}
