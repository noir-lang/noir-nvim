// Function body never closes — tests parser error recovery on EOF.
pub fn add(a: Field, b: Field) -> Field {
    let sum = a + b;
    if sum > 0 {
        sum
    // missing closing braces here on purpose
