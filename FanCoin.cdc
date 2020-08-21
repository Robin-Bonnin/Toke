import Toke from 0xf3fcd2c1a78f5eee
pub contract FanCoin {

    // Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    // Event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    // Event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)

    // Event that is emitted when a new burner resource is created
    pub event BurnerCreated()


    // Variable that holds the ID of the admins
    pub var nextFanAdminID: UInt32

    pub resource LeaderBoardManager {

        // holds the balance of a users tokens
        pub var fanBoard: {UInt32: UInt64}

        // initialize the balance at resource creation time
        init() {
            self.fanBoard = {}
        }

        pub fun createEmptyFanBoard(FanAdmin: &FanAdmin) {
            var FanAdminRef = FanAdmin as &FanAdmin
            var FanAdminID = FanAdminRef.vaultID
            self.fanBoard[FanAdminID] = 0
        }

        pub fun depositFanCoins(FanAdmin: &FanAdmin, NFT: &Toke.NFT){
            let FanAdminID = FanAdmin.vaultID
            self.fanBoard[FanAdminID] = self.fanBoard[FanAdminID]! + NFT.fanPoints
        }

        destroy() {
        }
    }

    pub resource FanAdmin {

        pub var vaultID: UInt32

        // initialize the balance at resource creation time
        init() {
            self.vaultID = FanCoin.nextFanAdminID
            FanCoin.nextFanAdminID = FanCoin.nextFanAdminID + UInt32(1)
        }

        destroy() {
        }
    }


    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //

    pub fun createEmptyFanAdmin(): @FanCoin.FanAdmin {
        return <-create FanAdmin()
    }

    pub fun createEmptyUserLeaderBoard(): @FanCoin.LeaderBoardManager {
        return <-create LeaderBoardManager()
    }


    init() {
        self.nextFanAdminID = 1
        // Emit an event that shows that the contract was initialized
    }
}
 