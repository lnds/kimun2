fn parse(s: &str) -> Result<Vec<Option<u8>>, Box<dyn std::error::Error>> {
    Ok(vec![s.parse().ok()])
}
