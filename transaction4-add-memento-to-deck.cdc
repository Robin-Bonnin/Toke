import Toke from 0xf3fcd2c1a78f5eee
transaction() {

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        
        // Borrow a reference to the deck to be added to
        let deckRef = admin.borrowDeck(deckID: 1)

        // Add the specified play ID
        deckRef.addMemento(mementoID:2)

        log("Memento added to a deck")
    }
}