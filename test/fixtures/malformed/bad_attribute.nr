// Malformed attribute and a function header missing its body.
use aztec::macros::aztec;

#[aztec
pub contract Broken {
    #[external("public"
    fn no_body(x: Field) -> Field

    #[storage]
    struct Storage<Context {
        counter: PublicMutable<u64, Context>,
    }
}
