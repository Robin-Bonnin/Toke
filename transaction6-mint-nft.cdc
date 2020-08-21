import Toke from 0x179b6b1cb6755e31

// This transaction creates a new play struct 
// and stores it in the Top Shot smart contract
// We currently stringify the metadata and instert it into the 
// transaction string, but want to use transaction arguments soon

transaction() {
    prepare(acct: AuthAccount) {

        // borrow a reference to the admin resource
        let admin = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("No admin resource in storage")
        admin.createMemento(metadata: {"test":"testint"})
    }

    execute {
        // Get the recipient's public account object
        let recipient = getAccount(0x045a1763c93006ca)

        // Get the Collection reference for the receiver
        // getting the public capability and borrowing a reference from it
        let receiverRef = recipient.getCapability(/public/NFTReceiver)!
                                .borrow<&{NonFungibleToken.NFTReceiver}>()!

        // Mint an NFT and deposit it into account 0x01's collection
        self.minterRef.mintNFT(recipient: receiverRef,name:"Fool")

        log("New NFT ")
  }
}