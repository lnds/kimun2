fn first(xs: &[&str]) -> Option<&&str> {
    xs.iter().find(|&&s| s.len() > 1)
}
