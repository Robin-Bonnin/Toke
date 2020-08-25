import FanCoin from 0xe03daebed8ca0615
import Toke from 0xf3fcd2c1a78f5eee


// This transaction sets up account 0x01 for the marketplace tutorial
// by publishing a Vault reference and creating an empty NFT Collection.
//Signed by the user
transaction {
    prepare(acct: AuthAccount) {
      // create a new vault instance with an initial balance of 30
    let FanBoard <- FanCoin.createEmptyUserLeaderBoard()
    let TokeUser <- Toke.createEmptyCollection() as! @Toke.Collection
    // Store the vault in the account storage
    acct.save<@FanCoin.LeaderBoardManager>(<-FanBoard, to: /storage/FanBoard)
    acct.save<@Toke.Collection>(<-TokeUser,to: /storage/TokeCollection)

    //Create the capability to the collection to store
    acct.link<&{Toke.MementoCollectionPublic}>(/public/TokeCollection, target: /storage/TokeCollection)

    log("User account initialized")
  }
}
 