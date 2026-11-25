macro_rules! getter {
    ($name:ident) => {
        fn $name(&self) -> bool {
            self.ready && self.open
        }
    };
}

fn check(a: bool) -> bool {
    a
}
