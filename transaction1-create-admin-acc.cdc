import FanCoin from 0xe03daebed8ca0615
import Toke from 0xf3fcd2c1a78f5eee

// This transaction sets up account 0x01 for the marketplace tutorial
// by publishing a Vault reference and creating an empty NFT Collection.
transaction {
    prepare(acct: AuthAccount) {
      // create a new vault instance with an initial balance of 30
    let FanAdmin <- FanCoin.createEmptyFanAdmin()

    let TokeAdmin <- Toke.createAdmin()
    // Store the vault in the account storage
    acct.save<@FanCoin.FanAdmin>(<-FanAdmin, to: /storage/FanAdmin)
    acct.save<@Toke.Admin>(<-TokeAdmin,to: /storage/TokeAdmin)
    log("Admin account created")
  }
}
 