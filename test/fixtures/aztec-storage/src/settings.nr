use aztec::protocol::traits::Packable;

#[derive(Eq, Packable)]
pub struct Settings {
    pub label: Field,
    pub fee_bps: u16,
}
