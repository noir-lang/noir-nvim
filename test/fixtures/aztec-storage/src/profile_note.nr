use aztec::{macros::notes::note, protocol::{address::AztecAddress, traits::Packable}};

#[derive(Eq, Packable)]
#[note]
pub struct ProfileNote {
    pub owner: AztecAddress,
    pub handle: str<31>,
    pub score: u32,
}
