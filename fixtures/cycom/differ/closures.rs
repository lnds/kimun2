fn fallback(o: Option<u8>) -> u8 {
    o.unwrap_or_else(|| 0)
}

fn spaces(bytes: &[u8]) -> usize {
    bytes.iter().take_while(|&&b| b == b' ').count()
}

fn first(words: &[&str]) -> Option<&&str> {
    words.first()
}
