// Storage-focused fixture: exercises Map, PublicMutable/Immutable, PrivateMutable,
// SinglePrivateImmutable, Owned wrappers, and a custom #[note] type.
mod profile_note;
mod settings;

use aztec::macros::aztec;

#[aztec]
pub contract AztecStorage {
    use crate::{profile_note::ProfileNote, settings::Settings};

    use aztec::{
        macros::{
            functions::{external, initializer, internal, view},
            storage::storage,
        },
        messages::message_delivery::MessageDelivery,
        protocol::address::AztecAddress,
        state_vars::{Map, Owned, PrivateMutable, PublicImmutable, PublicMutable, SinglePrivateImmutable},
    };

    use address_note::AddressNote;

    global MAX_LABEL_LEN: u32 = 31;

    #[storage]
    struct Storage<Context> {
        admin: SinglePrivateImmutable<AddressNote, Context>,
        settings: PublicImmutable<Settings, Context>,
        counter: PublicMutable<u64, Context>,
        balances: Map<AztecAddress, PublicMutable<u128, Context>, Context>,
        profiles: Map<AztecAddress, Owned<PrivateMutable<ProfileNote, Context>, Context>, Context>,
    }

    #[external("private")]
    #[initializer]
    fn constructor(admin: AztecAddress, label: str<31>, fee_bps: u16) {
        let admin_note = AddressNote { address: admin };
        self.storage.admin.initialize(admin_note).deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
        self.enqueue_self._init_settings(label, fee_bps);
    }

    #[external("public")]
    #[internal("public")]
    fn _init_settings(label: str<31>, fee_bps: u16) {
        self.storage.settings.initialize(Settings { label, fee_bps });
        self.storage.counter.write(0);
    }

    #[external("public")]
    #[view]
    fn read_counter() -> u64 {
        self.storage.counter.read()
    }

    #[external("public")]
    fn bump_counter(by: u64) {
        let prev = self.storage.counter.read();
        self.storage.counter.write(prev + by);
    }

    #[external("public")]
    #[view]
    fn balance_of(owner: AztecAddress) -> u128 {
        self.storage.public_balances_at(owner)
    }

    #[external("public")]
    fn set_balance(owner: AztecAddress, amount: u128) {
        self.storage.balances.at(owner).write(amount);
    }

    #[external("private")]
    fn upsert_profile(owner: AztecAddress, handle: str<31>, score: u32) {
        let note = ProfileNote { owner, handle, score };
        self
            .storage
            .profiles
            .at(owner)
            .initialize_or_replace(|_| note)
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("utility")]
    unconstrained fn profile_score(owner: AztecAddress) -> u32 {
        let n = self.storage.profiles.at(owner).get_note();
        n.score
    }

    fn public_balances_at(owner: AztecAddress) -> u128 {
        self.storage.balances.at(owner).read()
    }
}
