// Trimmed from aztec-packages/noir-projects/noir-contracts/contracts/app/simple_token_contract.
// Kept for syntax-coverage purposes only — not compiled standalone.
use aztec::macros::aztec;

#[aztec]
pub contract AztecToken {
    use std::ops::{Add, Sub};

    use compressed_string::FieldCompressedString;

    use aztec::{
        authwit::auth::compute_authwit_nullifier,
        context::{PrivateCall, PrivateContext},
        macros::{
            events::event,
            functions::{authorize_once, external, initializer, internal, only_self, view},
            storage::storage,
        },
        messages::message_delivery::MessageDelivery,
        protocol::address::AztecAddress,
        state_vars::{Map, Owned, PublicImmutable, PublicMutable},
    };

    use uint_note::{PartialUintNote, UintNote};
    use balance_set::BalanceSet;

    global INITIAL_TRANSFER_CALL_MAX_NOTES: u32 = 2;
    global RECURSIVE_TRANSFER_CALL_MAX_NOTES: u32 = 8;

    #[event]
    struct Transfer {
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
    }

    #[storage]
    struct Storage<Context> {
        balances: Owned<BalanceSet<Context>, Context>,
        total_supply: PublicMutable<u128, Context>,
        public_balances: Map<AztecAddress, PublicMutable<u128, Context>, Context>,
        symbol: PublicImmutable<FieldCompressedString, Context>,
        name: PublicImmutable<FieldCompressedString, Context>,
        decimals: PublicImmutable<u8, Context>,
    }

    #[external("public")]
    #[initializer]
    fn constructor(name: str<31>, symbol: str<31>, decimals: u8) {
        self.storage.name.initialize(FieldCompressedString::from_string(name));
        self.storage.symbol.initialize(FieldCompressedString::from_string(symbol));
        self.storage.decimals.initialize(decimals);
    }

    #[external("public")]
    #[view]
    fn public_get_name() -> FieldCompressedString {
        self.storage.name.read()
    }

    #[external("public")]
    #[view]
    fn public_balance_of(owner: AztecAddress) -> u128 {
        self.storage.public_balances.at(owner).read()
    }

    #[external("utility")]
    unconstrained fn private_balance_of(owner: AztecAddress) -> u128 {
        self.storage.balances.at(owner).balance_of()
    }

    #[external("public")]
    fn mint_publicly(to: AztecAddress, amount: u128) {
        let new_balance = self.storage.public_balances.at(to).read().add(amount);
        let supply = self.storage.total_supply.read().add(amount);
        self.storage.public_balances.at(to).write(new_balance);
        self.storage.total_supply.write(supply);
    }

    #[authorize_once("from", "authwit_nonce")]
    #[external("public")]
    fn public_transfer(from: AztecAddress, to: AztecAddress, amount: u128, authwit_nonce: Field) {
        let from_balance = self.storage.public_balances.at(from).read().sub(amount);
        self.storage.public_balances.at(from).write(from_balance);
        let to_balance = self.storage.public_balances.at(to).read().add(amount);
        self.storage.public_balances.at(to).write(to_balance);
    }

    #[external("private")]
    fn private_transfer(to: AztecAddress, amount: u128) {
        let from = self.msg_sender();

        let change = self.internal.subtract_balance(from, amount, INITIAL_TRANSFER_CALL_MAX_NOTES);
        self.storage.balances.at(from).add(change).deliver(MessageDelivery.ONCHAIN_UNCONSTRAINED);
        self.storage.balances.at(to).add(amount).deliver(MessageDelivery.ONCHAIN_UNCONSTRAINED);

        self.emit(Transfer { from, to, amount }).deliver_to(
            to,
            MessageDelivery.ONCHAIN_UNCONSTRAINED,
        );
    }

    #[external("private")]
    fn cancel_authwit(inner_hash: Field) {
        let on_behalf_of = self.msg_sender();
        let nullifier = compute_authwit_nullifier(on_behalf_of, inner_hash);
        self.context.push_nullifier(nullifier);
    }

    #[internal("private")]
    fn subtract_balance(account: AztecAddress, amount: u128, max_notes: u32) -> u128 {
        let subtracted = self.storage.balances.at(account).try_sub(amount, max_notes);
        assert(subtracted > 0 as u128, "Balance too low");
        if subtracted >= amount {
            subtracted - amount
        } else {
            let remaining = amount - subtracted;
            compute_recurse_subtract_balance_call(*self.context, account, remaining).call(
                self.context,
            )
        }
    }

    #[no_predicates]
    #[contract_library_method]
    fn compute_recurse_subtract_balance_call(
        context: PrivateContext,
        account: AztecAddress,
        remaining: u128,
    ) -> PrivateCall<25, 2, u128> {
        AztecToken::at(context.this_address())._recurse_subtract_balance(account, remaining)
    }

    #[only_self]
    #[external("private")]
    fn _recurse_subtract_balance(account: AztecAddress, amount: u128) -> u128 {
        self.internal.subtract_balance(account, amount, RECURSIVE_TRANSFER_CALL_MAX_NOTES)
    }
}
