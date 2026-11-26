// A cart's total, with a test module left out by default.

pub fn total(prices: &[u32], discount: u32) -> u32 {
    let mut sum = 0;
    for p in prices {
        sum += p;
    }
    if discount > 0 && sum > discount {
        sum - discount
    } else {
        sum
    }
}

pub fn kind(n: u32) -> u32 {
    match n {
        0 => 1,
        1 => 2,
        _ => n,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn totals() {
        if total(&[1, 2], 0) != 3 {
            panic!();
        }
    }
}
