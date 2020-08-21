// SetupAccount1Transaction.cdc
import Toke from 0x179b6b1cb6755e31
import FanCoin from 0xf3fcd2c1a78f5eee
import NonFungibleToken from 0x01cf0e2f2f715450


// This transaction sets up account 0x01 for the marketplace tutorial
// by publishing a Vault reference and creating an empty NFT Collection.
transaction {
    prepare(acct: AuthAccount) {
      // create a new vault instance with an initial balance of 30
    let FanBoard <- FanCoin.createEmptyUserLeaderBoard()

    let TokeUser <- Toke.createEmptyCollection()
    // Store the vault in the account storage
    acct.save<@FanCoin.LeaderBoardManager>(<-FanBoard, to: /storage/FanBoard)
    acct.save<@NonFungibleToken.Collection>(<-TokeUser,to: /storage/TokeCollection)
  }
}
 