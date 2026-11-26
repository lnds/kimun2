macro_rules! double {
    ($self:expr) => {
        $self * 2
    };
}

fn twice(x: i32) -> i32 {
    double!(x)
}
