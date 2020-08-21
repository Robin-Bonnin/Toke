//Setup deck
import Toke from 0x179b6b1cb6755e31

// This transaction is for the admin to create a new set resource
// and store it in the top shot smart contract
transaction() {
    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")

        // Create a set with the specified name
        admin.createDeck(name: "Cat stuff")
        log("Deck created")
    }
}
