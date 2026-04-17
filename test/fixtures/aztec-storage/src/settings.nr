use aztec::protocol::traits::Packable;

#[derive(Eq, Packable)]
pub struct Settings {
    pub label: str<31>,
    pub fee_bps: u16,
}
