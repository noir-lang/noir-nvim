use crate::PI;

pub struct Circle {
    radius: Field,
}

impl Circle {
    pub fn new(radius: Field) -> Self {
        Self { radius }
    }

    pub fn area(self) -> Field {
        PI * self.radius * self.radius
    }
}

pub enum Shape {
    Circle(Circle),
    Square(Field),
}
