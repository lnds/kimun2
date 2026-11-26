macro_rules! double {
    ($self:expr) => {
        $self * 2
    };
}

macro_rules! sum {
    ($($x:expr),*) => { 0 $(+ $x)* };
}

fn twice(x: i32) -> i32 {
    double!(x) + sum!(x, 1)
}
