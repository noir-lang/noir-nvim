pub fn pow(base: Field, exp: u32) -> Field {
    let mut acc: Field = 1;
    for _ in 0..exp {
        acc *= base;
    }
    acc
}

pub fn min<T>(a: T, b: T) -> T
where
    T: std::cmp::Ord,
{
    if a < b {
        a
    } else {
        b
    }
}

fn raw_xor(a: u32, b: u32) -> u32 {
    a ^ b
}

pub fn safe_xor(a: u32, b: u32) -> u32 {
    // Safety: bitwise xor is total over u32.
    unsafe { raw_xor(a, b) }
}
