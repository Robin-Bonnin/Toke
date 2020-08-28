import FanCoin from 0xe03daebed8ca0615
import Toke from 0xf3fcd2c1a78f5eee
// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: Vault Balance = 40, NFT.id = 1
// Account 0x02: Vault Balance = 20, No NFTs
pub fun main(): {UInt32:String} {
     // Get the public account object for account 0x01
          let acct = getAccount(0xTODELETE)
      
          // Find the public Sale reference to their Collection
          let acctRef = acct.getCapability(/public/TokePublic)!
                                     .borrow<&{Toke.AdminPublic}>()!
      
          // Los the NFTs that are for sale
          log("Account 1 NFTs for sale")
          log(acctRef.listDecks())
         
          return acctRef.listDecks()
}
 