//! Crate docs.

/* outer /* nested */ still comment */
fn main() {
    let raw = r#"// not a comment "quoted" "#;
    let bytes = br"/* not a comment";
    let c = '"';
    let s = "a \" // inside";
    let r = 'x'; // trailing comment makes this code
}

/// Item docs.
struct Holder<'a> {
    name: &'a str, /* inline */
}

/*
multi-line comment
*/
