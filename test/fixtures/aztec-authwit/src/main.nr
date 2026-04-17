// Authwit-focused fixture: exercises both private and public authwit checks,
// the modern #[authorize_once] attribute, manual nullifier cancellation,
// and message-hash computation.
use aztec::macros::aztec;

#[aztec]
pub contract AztecAuthwit {
    use aztec::{
        authwit::auth::{
            assert_current_call_valid_authwit, assert_current_call_valid_authwit_public,
            compute_authwit_message_hash_from_call, compute_authwit_nullifier, set_authorized,
        },
        macros::{
            functions::{authorize_once, external, only_self},
            storage::storage,
        },
        protocol::{abis::function_selector::FunctionSelector, address::AztecAddress, traits::ToField},
        state_vars::PublicMutable,
    };

    #[storage]
    struct Storage<Context> {
        last_caller: PublicMutable<AztecAddress, Context>,
    }

    // Modern attribute-driven authwit check.
    #[authorize_once("on_behalf_of", "authwit_nonce")]
    #[external("public")]
    fn delegated_action(on_behalf_of: AztecAddress, payload: Field, authwit_nonce: Field) {
        self.storage.last_caller.write(on_behalf_of);
        let _ = payload;
    }

    // Manual private authwit assertion.
    #[external("private")]
    fn private_check(on_behalf_of: AztecAddress) {
        if !on_behalf_of.eq(self.msg_sender()) {
            assert_current_call_valid_authwit::<1>(self.context, on_behalf_of);
        }
    }

    // Manual public authwit assertion.
    #[external("public")]
    fn public_check(on_behalf_of: AztecAddress) {
        if !on_behalf_of.eq(self.msg_sender()) {
            assert_current_call_valid_authwit_public(self.context, on_behalf_of);
        }
        self.storage.last_caller.write(on_behalf_of);
    }

    // Cancel an outstanding authwit by pushing its nullifier.
    #[external("private")]
    fn cancel_authwit(inner_hash: Field) {
        let on_behalf_of = self.msg_sender();
        let nullifier = compute_authwit_nullifier(on_behalf_of, inner_hash);
        self.context.push_nullifier(nullifier);
    }

    // Pre-authorize a downstream call from the contract itself.
    #[external("public")]
    #[only_self]
    fn pre_authorize_swap(
        target: AztecAddress,
        selector: FunctionSelector,
        args_hash: Field,
        nonce: Field,
    ) {
        let message_hash = compute_authwit_message_hash_from_call(
            target,
            self.address,
            self.context.chain_id(),
            self.context.version(),
            selector,
            [args_hash, nonce],
        );
        set_authorized(self.context, message_hash, true);
    }
}
