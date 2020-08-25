import Toke from 0xf3fcd2c1a78f5eee
import NonFungibleToken from 0x179b6b1cb6755e31

// This transaction creates a new play struct 
// and stores it in the Top Shot smart contract
// We currently stringify the metadata and instert it into the 
// transaction string, but want to use transaction arguments soon
//Signed by the admin
transaction() {
    let adminRef: &Toke.Admin
    prepare(acct: AuthAccount) {

        // borrow a reference to the admin resource
        self.adminRef = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("No admin resource in storage")
    }
    execute{
        // Borrow a reference to the specified deck
        let setRef = self.adminRef.borrowDeck(deckID: 1)

        // Mint a new NFT
        let moment1 <- setRef.mintMemento(mementoID: 2,fanPoints:3000)
        // Get the recipient's public account object
        let recipient = getAccount(0xf669cb8d41ce0c74)
        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(/public/TokeCollection)!.borrow<&{Toke.MementoCollectionPublic}>()
            ?? panic("Cannot borrow a reference to the recipient's moment collection")

        // deposit the NFT in the receivers collection
        receiverRef.deposit(token: <-moment1)

        log("New NFT minted")
  }
}
 