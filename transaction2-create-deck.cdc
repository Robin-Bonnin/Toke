//Setup deck
import Toke from 0xf3fcd2c1a78f5eee
// This transaction is for the admin to create a new set resource
// and store it in the top shot smart contract
transaction() {
    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        log("Before creating a deck")
        // Create a deck with the specified name
        admin.createDeck(name: "Weirdo stuff")
        log("Deck created")
    }
}
 