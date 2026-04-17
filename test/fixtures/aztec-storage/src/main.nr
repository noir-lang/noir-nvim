// Storage-focused fixture: exercises Map, PublicMutable/Immutable, PrivateMutable,
// SinglePrivateImmutable, Owned wrappers, and a custom #[note] type.
mod profile_note;
mod settings;

use aztec::macros::aztec;

#[aztec]
pub contract AztecStorage {
    use crate::{profile_note::ProfileNote, settings::Settings};

    use aztec::{
        macros::{functions::{external, initializer, view}, storage::storage},
        messages::message_delivery::MessageDelivery,
        protocol::address::AztecAddress,
        state_vars::{Map, Owned, PrivateMutable, PublicImmutable, PublicMutable, SinglePrivateImmutable},
    };

    #[storage]
    struct Storage<Context> {
        admin: PublicImmutable<AztecAddress, Context>,
        settings: PublicImmutable<Settings, Context>,
        counter: PublicMutable<u64, Context>,
        balances: Map<AztecAddress, PublicMutable<u128, Context>, Context>,
        profile_template: SinglePrivateImmutable<ProfileNote, Context>,
        profiles: Owned<PrivateMutable<ProfileNote, Context>, Context>,
    }

    #[external("public")]
    #[initializer]
    fn constructor(admin: AztecAddress, label: Field, fee_bps: u16) {
        self.storage.admin.initialize(admin);
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
        self.storage.balances.at(owner).read()
    }

    #[external("public")]
    fn set_balance(owner: AztecAddress, amount: u128) {
        self.storage.balances.at(owner).write(amount);
    }

    #[external("private")]
    fn upsert_profile(owner: AztecAddress, handle: Field, score: u32) {
        self
            .storage
            .profiles
            .at(owner)
            .initialize_or_replace(|_| ProfileNote { owner, handle, score })
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("utility")]
    unconstrained fn profile_exists(owner: AztecAddress) -> bool {
        self.storage.profiles.at(owner).is_initialized()
    }
}
