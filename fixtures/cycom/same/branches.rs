const X: i32 = if true { 1 } else { 2 };

struct S;

impl S {
    fn m(&self, a: i32) -> i32 {
        let f = |x: i32| if x > 0 { x } else { -x };
        fn inner(y: i32) -> i32 { if y > 1 && y < 5 { 1 } else { 0 } }
        match a {
            1 => f(a),
            2 | 3 => inner(a),
            _ => 0,
        }
    }
}

fn top(v: Option<i32>) -> i32 {
    // if this were code
    let s = "if while for";
    while let Some(x) = v { if x > 0 || x < -1 { return x; } }
    for i in 0..3 { loop { break; } }
    v.unwrap_or(0)
}
