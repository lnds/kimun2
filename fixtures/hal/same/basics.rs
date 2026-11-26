use std::collections::HashMap;

/// Counts words longer than `min`.
pub fn count(text: &str, min: usize) -> HashMap<String, usize> {
    let mut seen = HashMap::new();
    for word in text.split(' ') {
        if word.len() > min && !word.is_empty() {
            *seen.entry(word.to_string()).or_insert(0) += 1;
        } else if word.len() == min {
            continue;
        }
    }
    seen
}

fn pick(x: Option<i32>) -> i32 {
    match x {
        Some(n) if n > 0 => n * 2,
        Some(_) => 0,
        None => -1,
    }
}

fn scale(v: &[i32], k: i32) -> Vec<i32> {
    v.iter().map(|x| x * k).collect()
}

#[derive(Debug, Default)]
struct Point {
    x: i32,
    y: i32,
}

impl Point {
    fn norm(&self) -> i32 {
        let s = "a string counts nothing";
        let _ = s;
        loop {
            return (self.x * self.x + self.y * self.y) as i32;
        }
    }
}

fn origin(a: bool) -> Point {
    assert!(if a { true } else { false });
    Point::default()
}

#[cfg(test)]
mod tests {
    #[test]
    fn left_out() {
        assert_eq!(super::pick(Some(1)), 2);
    }
}
