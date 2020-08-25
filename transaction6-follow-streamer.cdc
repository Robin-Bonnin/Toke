import FanCoin from 0xe03daebed8ca0615
import Toke from 0xf3fcd2c1a78f5eee


// This transaction sets up account 0x01 for the marketplace tutorial
// by publishing a Vault reference and creating an empty NFT Collection.
//Signed by the user
transaction {
    let leaderboard: &FanCoin.LeaderBoardManager

    prepare(acct: AuthAccount) {
    self.leaderboard = acct.borrow<&FanCoin.LeaderBoardManager>(from:/storage/FanBoard)!
    }

    execute {

      // Get the recipient's public account object
    let admin = getAccount(0x120e725050340cab)
    
    // get the Collection reference for the receiver
    let adminRef = admin.getCapability(/public/AdminPublic)!.borrow<&{FanCoin.AdminPublic}>()!

    self.leaderboard.createEmptyFanBoard(adminPublic: adminRef as &{FanCoin.AdminPublic})

    log("Streamer followed")
  }
}
 