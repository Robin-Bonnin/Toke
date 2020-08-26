import FanCoin from 0xe03daebed8ca0615
import Toke from 0xf3fcd2c1a78f5eee
// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: Vault Balance = 40, NFT.id = 1
// Account 0x02: Vault Balance = 20, No NFTs
pub fun main() {
    // Get the accounts' public account objects
    let acctStreamer = getAccount(0x120e725050340cab)
    // Get references to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    //let adminRef = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)!
    //let deck = adminRef.borrowDeck(deckID:1)
    // Log the Vault balance of both accounts and ensure they are
    // the correct numbers.
    // Account 0x01 should have 40.
    // Account 0x02 should have 20.
    
    //log("Name of deck 1")
    //log(adminRef.getDeckName(deckID:1))
    //log("Deck 1 mementos")
    //log(deck.listMementosOfDeck())
}
 