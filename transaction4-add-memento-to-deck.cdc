import Toke from 0x179b6b1cb6755e31

// This transaction is how a Top Shot admin adds a created play to a set

transaction() {

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        
        // Borrow a reference to the set to be added to
        let deckRef = admin.borrowDeck(deckID: 1)

        // Add the specified play ID
        deckRef.addMemento(mementoID:1)
    }
}