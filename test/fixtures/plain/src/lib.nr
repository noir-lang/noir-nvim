mod math;
mod shapes;

use crate::shapes::{Circle, Shape};

global PI: Field = 3;
global MAX_ITEMS: u32 = 16;

pub struct Container<T, let N: u32> {
    items: [T; N],
    len: u32,
}

impl<T, let N: u32> Container<T, N> {
    pub fn new(default: T) -> Self {
        Self { items: [default; N], len: 0 }
    }

    pub fn push(&mut self, value: T) {
        assert(self.len < N, "container full");
        self.items[self.len] = value;
        self.len += 1;
    }

    pub fn len(self) -> u32 {
        self.len
    }
}

pub trait Summable {
    fn zero() -> Self;
    fn add(self, other: Self) -> Self;
}

impl Summable for Field {
    fn zero() -> Self {
        0
    }

    fn add(self, other: Self) -> Self {
        self + other
    }
}

pub fn sum<T>(values: [T; 4]) -> T
where
    T: Summable,
{
    let mut acc = T::zero();
    for v in values {
        acc = acc.add(v);
    }
    acc
}

pub unconstrained fn debug_log<T>(value: T) {
    let _ = value;
}

pub fn area_of(shape: Shape) -> Field {
    match shape {
        Shape::Circle(c) => c.area(),
        Shape::Square(side) => side * side,
    }
}

#[test]
fn test_sum_fields() {
    let values: [Field; 4] = [1, 2, 3, 4];
    assert(sum(values) == 10);
}

#[test(should_fail_with = "container full")]
fn test_container_overflow() {
    let mut c: Container<Field, 1> = Container::new(0);
    c.push(1);
    c.push(2);
}
