import NonFungibleToken from 0x01cf0e2f2f715450

pub contract Toke : NonFungibleToken {

    // Emitted when the Toke contract is created
    pub event ContractInitialized()
    // Emitted when a new Play struct is created
    pub event MementoCreated(id: UInt32, metadata: {String:String})

    // Events for Set-Related actions
    //
    // Emitted when a new special loot event is started
    pub event DeckCreated(deckID: UInt32)

    pub event SpecialLootEventStarted(lootID:UInt32)
    // Emitted when a new special loot event is finished
    pub event SpecialLootEventFinished(setID: UInt32, playID: UInt32, numMoments: UInt32)
    // Emitted when a memento is minted
    pub event MementoMinted(NFTID: UInt64, mementoID: UInt32, deckID: UInt32)
    pub event MementoRetiredFromDeck(deckID: UInt32, mementoID: UInt32, numMoments: UInt32)

    // Events for Collection-related actions
    //
    // Emitted when a moment is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)
    // Emitted when a moment is deposited into a Collection
    pub event Deposit(id: UInt64, to: Address?)

    pub event MementoAddedToDeck(deckID: UInt32, mementoID: UInt32)

    pub event DeckLocked(deckID: UInt32)

    // Emitted when a Moment is destroyed
    pub event MementoDestroyed(id: UInt64)

    // Variables
    // Variable size dictionary of Play structs
    access(self) var mementoDatas: {UInt32: Memento}

    // Variable size dictionary of SetData structs
    access(self) var deckDatas: {UInt32: DeckData}

    // Variable size dictionary of Set resources
    access(self) var decks: @{UInt32: Deck}

    // The ID that is used to create Plays. 
    // Every time a Play is created, playID is assigned 
    // to the new Play's ID and then is incremented by 1.
    pub var nextMementoID: UInt32

    // The ID that is used to create Sets. Every time a Set is created
    // setID is assigned to the new set's ID and then is incremented by 1.
    pub var nextDeckID: UInt32

    // The total number of Top shot Moment NFTs that have been created
    // Because NFTs can be destroyed, it doesn't necessarily mean that this
    // reflects the total number of NFTs in existence, just the number that
    // have been minted to date. Also used as global moment IDs for minting.
    pub var totalSupply: UInt64


    pub struct Memento {

        // The unique ID for the Play
        pub let mementoID: UInt32

        // Stores all the metadata about the play as a string mapping
        // This is not the long term way NFT metadata will be stored. It's a temporary
        // construct while we figure out a better way to do metadata.
        //
        pub let metadata: {String: String}

        init(metadata: {String: String}) {
            pre {
                metadata.length != 0: "New Play metadata cannot be empty"
            }
            self.mementoID = Toke.nextMementoID
            self.metadata = metadata

            // Increment the ID so that it isn't used again
            Toke.nextMementoID = Toke.nextMementoID + UInt32(1)

            emit MementoCreated(id: self.mementoID, metadata: metadata)
        }
    }


    pub struct DeckData {

        // Unique ID for the Set
        pub let deckID: UInt32

        // Name of the Set
        // ex. "Times when the Toronto Raptors choked in the playoffs"
        pub let name: String


        init(name: String) {
            pre {
                name.length > 0: "New Set name cannot be empty"
            }
            self.deckID = Toke.nextDeckID
            self.name = name

            // Increment the setID so that it isn't used again
            Toke.nextDeckID = Toke.nextDeckID + UInt32(1)

            emit DeckCreated(deckID: self.deckID)
        }
    }



    // Admin can also retire Plays from the Set, meaning that the retired
    // Play can no longer have Moments minted from it.
    //
    // If the admin locks the Set, no more Plays can be added to it, but 
    // Moments can still be minted.
    //
    // If retireAll() and lock() are called back-to-back, 
    // the Set is closed off forever and nothing more can be done with it.
    pub resource Deck {

        // Unique ID for the set
        pub let deckID: UInt32

        pub let deckVisible: Bool

        // Array of plays that are a part of this set.
        // When a play is added to the set, its ID gets appended here.
        // The ID does not get removed from this array when a Play is retired.
        pub var mementos: [UInt32]

        // Map of Play IDs that Indicates if a Play in this Set can be minted.
        // When a Play is added to a Set, it is mapped to false (not retired).
        // When a Play is retired, this is set to true and cannot be changed.
        pub var retired: {UInt32: Bool}

        // Indicates if the Set is currently locked.
        // When a Set is created, it is unlocked 
        // and Plays are allowed to be added to it.
        // When a set is locked, Plays cannot be added.
        // A Set can never be changed from locked to unlocked,
        // the decision to lock a Set it is final.
        // If a Set is locked, Plays cannot be added, but
        // Moments can still be minted from Plays
        // that exist in the Set.
        pub var locked: Bool

        // Mapping of Play IDs that indicates the number of Moments 
        // that have been minted for specific Plays in this Set.
        // When a Moment is minted, this value is stored in the Moment to
        // show its place in the Set, eg. 13 of 60.
        pub var numberMintedPerMemento: {UInt32: UInt32}

        init(name: String) {
            self.deckID = Toke.nextDeckID
            self.mementos = []
            self.deckVisible = false
            self.retired = {}
            self.locked = false
            self.numberMintedPerMemento = {}

            // Create a new SetData for this Set and store it in contract storage
            Toke.deckDatas[self.deckID] = DeckData(name: name)
        }

        pub fun listMementosOfDeck(): [UInt32] {
            pre {
                !self.deckVisible : "Cannot list the mementos of this deck, the deck is set a not public"
            }
            return self.mementos
        }


        pub fun unlockDeck(){
            self.locked = false

        }

        // addPlay adds a play to the set
        //
        // Parameters: playID: The ID of the Play that is being added
        //
        // Pre-Conditions:
        // The Play needs to be an existing play
        // The Set needs to be not locked
        // The Play can't have already been added to the Set
        //
        pub fun addMemento(mementoID: UInt32) {
            pre {
                Toke.mementoDatas[mementoID] != nil: "Cannot add the Play to Set: Play doesn't exist."
                !self.locked: "Cannot add the play to the Set after the set has been locked."
                self.numberMintedPerMemento[mementoID] == nil: "The play has already beed added to the set."
            }

            // Add the Play to the array of Plays
            self.mementos.append(mementoID)

            // Open the Play up for minting
            self.retired[mementoID] = false

            // Initialize the Moment count to zero
            self.numberMintedPerMemento[mementoID] = 0

            emit MementoAddedToDeck(deckID: self.deckID, mementoID: mementoID)
        }

        // addPlays adds multiple Plays to the Set
        //
        // Parameters: playIDs: The IDs of the Plays that are being added
        //                      as an array
        //
        pub fun addMementos(mementoIDs: [UInt32]) {
            for memento in mementoIDs {
                self.addMemento(mementoID: memento)
            }
        }

        // retirePlay retires a Play from the Set so that it can't mint new Moments
        //
        // Parameters: playID: The ID of the Play that is being retired
        //
        // Pre-Conditions:
        // The Play is part of the Set and not retired (available for minting).
        // 
        pub fun retireMemento(mementoID: UInt32) {
            pre {
                self.retired[mementoID] != nil: "Cannot retire the Play: Play doesn't exist in this set!"
            }

            if !self.retired[mementoID]! {
                self.retired[mementoID] = true
                emit MementoRetiredFromDeck(deckID: self.deckID, mementoID: mementoID, numMoments: self.numberMintedPerMemento[mementoID]!)
            }
        }

        // retireAll retires all the plays in the Set
        // Afterwards, none of the retired Plays will be able to mint new Moments
        //
        pub fun retireAll() {
            for memento in self.mementos {
                self.retireMemento(mementoID: memento)
            }
        }

        // lock() locks the Set so that no more Plays can be added to it
        //
        // Pre-Conditions:
        // The Set should not be locked
        pub fun lock() {
            if !self.locked {
                self.locked = true
                emit DeckLocked(deckID: self.deckID)
            }
        }

        // mintMoment mints a new Moment and returns the newly minted Moment
        // 
        // Parameters: playID: The ID of the Play that the Moment references
        //
        // Pre-Conditions:
        // The Play must exist in the Set and be allowed to mint new Moments
        //
        // Returns: The NFT that was minted
        // 
        pub fun mintMemento(mementoID: UInt32, fanPoints: UInt64): @NFT {
            pre {
                self.retired[mementoID] != nil: "Cannot mint the moment: This play doesn't exist."
                !self.retired[mementoID]!: "Cannot mint the moment from this play: This play has been retired."
            }

            // Gets the number of Moments that have been minted for this Play
            // to use as this Moment's serial number
            let numInPlay = self.numberMintedPerMemento[mementoID]!

            // Mint the new moment
            let newMoment: @NFT <- create NFT(serialNumber: numInPlay + UInt32(1),
                                              mementoID: mementoID,
                                              deckID: self.deckID,fanPoints: fanPoints)

            // Increment the count of Moments minted for this Play
            self.numberMintedPerMemento[mementoID] = numInPlay + UInt32(1)

            return <-newMoment
        }

        // batchMintMoment mints an arbitrary quantity of Moments 
        // and returns them as a Collection
        //
        // Parameters: playID: the ID of the Play that the Moments are minted for
        //             quantity: The quantity of Moments to be minted
        //
        // Returns: Collection object that contains all the Moments that were minted
        //
        pub fun batchMintMemento(mementoID: UInt32, quantity: UInt64, fanPoints: UInt64): @Collection {
            let newCollection <- create Collection()

            var i: UInt64 = 0
            while i < quantity {
                newCollection.deposit(token: <-self.mintMemento(mementoID: mementoID, fanPoints: fanPoints))
                i = i + UInt64(1)
            }

            return <-newCollection
        }
    }


    pub struct MementoData {

        // The ID of the Set that the Moment comes from
        pub let deckID: UInt32

        // The ID of the Play that the Moment references
        pub let mementoID: UInt32

        // The place in the edition that this Moment was minted
        // Otherwise know as the serial number
        pub let serialNumber: UInt32

        init(deckID: UInt32, mementoID: UInt32, serialNumber: UInt32) {
            self.deckID = deckID
            self.mementoID = mementoID
            self.serialNumber = serialNumber
        }

    }


    // The resource that represents the Moment NFTs
    //
    pub resource NFT: NonFungibleToken.INFT {

        // Global unique moment ID
        pub let id: UInt64
        
        // Struct of Moment metadata
        pub let data: MementoData
        // Number of fanpoints fans will get when doing actions with their tokens
        pub var fanPoints: UInt64

        init(serialNumber: UInt32, mementoID: UInt32, deckID: UInt32, fanPoints: UInt64) {
            // Increment the global Moment IDs
            Toke.totalSupply = Toke.totalSupply + UInt64(1)

            self.id = Toke.totalSupply
            self.fanPoints = fanPoints

            // Set the metadata struct
            self.data = MementoData(deckID: deckID, mementoID: mementoID, serialNumber: serialNumber)

            emit MementoMinted(NFTID: self.id, mementoID: mementoID, deckID: self.data.deckID)
        }

        // If the Moment is destroyed, emit an event to indicate 
        // to outside ovbservers that it has been destroyed
        destroy() {
            emit MementoDestroyed(id: self.id)
        }
    }

    // Admin is a special authorization resource that 
    // allows the owner to perform important functions to modify the 
    // various aspects of the Plays, Sets, and Moments
    //
    pub resource Admin {

        // createPlay creates a new Play struct 
        // and stores it in the Plays dictionary in the TopShot smart contract
        //
        // Parameters: metadata: A dictionary mapping metadata titles to their data
        //                       example: {"Player Name": "Kevin Durant", "Height": "7 feet"}
        //                               (because we all know Kevin Durant is not 6'9")
        //
        // Returns: the ID of the new Play object
        //
        pub fun createMemento(metadata: {String: String}): UInt32 {
            // Create the new Play
            var newMemento = Memento(metadata: metadata)
            let newID = newMemento.mementoID

            // Store it in the contract storage
            Toke.mementoDatas[newID] = newMemento

            return newID
        }

        // createSet creates a new Set resource and stores it
        // in the sets mapping in the TopShot contract
        //
        // Parameters: name: The name of the Set
        //
        pub fun createDeck(name: String) {
            // Create the new Set
            var newDeck <- create Deck(name: name)

            // Store it in the sets mapping field
            Toke.decks[newDeck.deckID] <-! newDeck
        }

        // borrowSet returns a reference to a set in the TopShot
        // contract so that the admin can call methods on it
        //
        // Parameters: setID: The ID of the Set that you want to
        // get a reference to
        //
        // Returns: A reference to the Set with all of the fields
        // and methods exposed
        //
        pub fun borrowDeck(deckID: UInt32): &Deck {
            pre {
                Toke.decks[deckID] != nil: "Cannot borrow Set: The Set doesn't exist"
            }
            
            // Get a reference to the Set and return it
            // use `&` to indicate the reference to the object and type
            return &Toke.decks[deckID] as &Deck
        }

        // createNewAdmin creates a new Admin resource
        //
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }   

    // This is the interface that users can cast their Moment Collection as
    // to allow others to deposit Moments into their Collection. It also allows for reading
    // the IDs of Moments in the Collection.
    pub resource interface MementoCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowMemento(id: UInt64): &Toke.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id): 
                    "Cannot borrow Moment reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection is a resource that every user who owns NFTs 
    // will store in their account to manage their NFTS
    //
    pub resource Collection: MementoCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic { 
        // Dictionary of Moment conforming tokens
        // NFT is a resource type with a UInt64 ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        // withdraw removes an Moment from the Collection and moves it to the caller
        //
        // Parameters: withdrawID: The ID of the NFT 
        // that is to be removed from the Collection
        //
        // returns: @NonFungibleToken.NFT the token that was withdrawn
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {

            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("Cannot withdraw: Moment does not exist in the collection")

            emit Withdraw(id: token.id, from: self.owner?.address)
            
            // Return the withdrawn token
            return <-token
        }

        // batchWithdraw withdraws multiple tokens and returns them as a Collection
        //
        // Parameters: ids: An array of IDs to withdraw
        //
        // Returns: @NonFungibleToken.Collection: A collection that contains
        //                                        the withdrawn moments
        //
        pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            // Create a new empty Collection
            var batchCollection <- create Collection()
            
            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            
            // Return the withdrawn tokens
            return <-batchCollection
        }

        // deposit takes a Moment and adds it to the Collections dictionary
        //
        // Paramters: token: the NFT to be deposited in the collection
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            
            // Cast the deposited token as a TopShot NFT to make sure
            // it is the correct type
            let token <- token as! @Toke.NFT

            // Get the token's ID
            let id = token.id

            // Add the new token to the dictionary
            let oldToken <- self.ownedNFTs[id] <- token

            // Only emit a deposit event if the Collection 
            // is in an account's storage
            if self.owner?.address != nil {
                emit Deposit(id: id, to: self.owner?.address)
            }

            // Destroy the empty old token that was "removed"
            destroy oldToken
        }

        // batchDeposit takes a Collection object as an argument
        // and deposits each contained NFT into this Collection
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()

            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }

            // Destroy the empty Collection
            destroy tokens
        }

        // getIDs returns an array of the IDs that are in the Collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT Returns a borrowed reference to a Moment in the Collection
        // so that the caller can read its ID
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        //
        // Note: This only allows the caller to read the ID of the NFT,
        // not any topshot specific data. Please use borrowMoment to 
        // read Moment data.
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowMoment returns a borrowed reference to a Moment
        // so that the caller can read data and call methods from it.
        // They can use this to read its setID, playID, serialNumber,
        // or any of the setData or Play data associated with it by
        // getting the setID or playID and reading those fields from
        // the smart contract.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowMemento(id: UInt64): &Toke.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Toke.NFT
            } else {
                return nil
            }
        }

        // If a transaction destroys the Collection object,
        // All the NFTs contained within are also destroyed!
        // Much like when Damien Lillard destroys the hopes and
        // dreams of the entire city of Houston.
        //
        destroy() {
            destroy self.ownedNFTs
        }
    }


    
    // -----------------------------------------------------------------------
    // TopShot contract-level function definitions
    // -----------------------------------------------------------------------

    // createEmptyCollection creates a new, empty Collection object so that
    // a user can store it in their account storage.
    // Once they have a Collection in their storage, they are able to receive
    // Moments in transactions.
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <-create Toke.Collection()
    }

    //Create an admin for streamer to administrate their own mementos 
    pub fun createAdmin(): @Toke.Admin {
        return <- create Toke.Admin()
    }

    
    // getPlayMetaData returns all the metadata associated with a specific Play
    // 
    // Parameters: playID: The id of the Play that is being searched
    //
    // Returns: The metadata as a String to String mapping optional
    pub fun getMementoMetaData(mementoID: UInt32): {String: String}? {
        return self.mementoDatas[mementoID]?.metadata
    }

    // getPlayMetaDataByField returns the metadata associated with a 
    //                        specific field of the metadata
    //                        Ex: field: "Team" will return something
    //                        like "Memphis Grizzlies"
    // 
    // Parameters: playID: The id of the Play that is being searched
    //             field: The field to search for
    //
    // Returns: The metadata field as a String Optional
    pub fun getMementoMetaDataByField(mementoID: UInt32, field: String): String? {
        // Don't force a revert if the playID or field is invalid
        if let memento = Toke.mementoDatas[mementoID] {
            return memento.metadata[field]
        } else {
            return nil
        }
    }


    // getSetName returns the name that the specified Set
    //            is associated with.
    // 
    // Parameters: setID: The id of the Set that is being searched
    //
    // Returns: The name of the Set
    pub fun getDeckName(deckID: UInt32): String? {
        // Don't force a revert if the setID is invalid
        return Toke.deckDatas[deckID]?.name
    }

    // getSetIDsByName returns the IDs that the specified Set name
    //                 is associated with.
    // 
    // Parameters: setName: The name of the Set that is being searched
    //
    // Returns: An array of the IDs of the Set if it exists, or nil if doesn't
    pub fun getDeckIDsByName(deckName: String): [UInt32]? {
        var deckIDs: [UInt32] = []

        // Iterate through all the setDatas and search for the name
        for deckData in Toke.deckDatas.values {
            if deckName == deckData.name {
                // If the name is found, return the ID
                deckIDs.append(deckData.deckID)
            }
        }

        // If the name isn't found, return nil
        // Don't force a revert if the setName is invalid
        if deckIDs.length == 0 {
            return nil
        } else {
            return deckIDs
        }
    }
    // getPlaysInSet returns the list of Play IDs that are in the Set
    // 
    // Parameters: setID: The id of the Set that is being searched
    //
    // Returns: An array of Play IDs
    pub fun getMementosInDeck(deckID: UInt32): [UInt32]? {
        // Don't force a revert if the setID is invalid
        return Toke.decks[deckID]?.mementos
    }
    // isEditionRetired returns a boolean that indicates if a Set/Play combo
    //                  (otherwise known as an edition) is retired.
    //                  If an edition is retired, it still remains in the Set,
    //                  but Moments can no longer be minted from it.
    // 
    // Parameters: setID: The id of the Set that is being searched
    //             playID: The id of the Play that is being searched
    //
    // Returns: Boolean indicating if the edition is retired or not
    pub fun isMementoRetired(deckID: UInt32, mementoID: UInt32): Bool? {
        // Don't force a revert if the set or play ID is invalid
        // Remove the set from the dictionary to get its field
        if let deckToRead <- Toke.decks.remove(key: deckID) {

            // See if the Play is retired from this Set
            let retired = deckToRead.retired[mementoID]

            // Put the Set back in the contract storage
            Toke.decks[deckID] <-! deckToRead

            // Return the retired status
            return retired
        } else {

            // If the Set wasn't found, return nil
            return nil
        }
    }

    // isSetLocked returns a boolean that indicates if a Set
    //             is locked. If it's locked, 
    //             new Plays can no longer be added to it,
    //             but Moments can still be minted from Plays the set contains.
    // 
    // Parameters: setID: The id of the Set that is being searched
    //
    // Returns: Boolean indicating if the Set is locked or not
    pub fun isDeckLocked(deckID: UInt32): Bool? {
        // Don't force a revert if the setID is invalid
        return Toke.decks[deckID]?.locked
    }

        // getNumMomentsInEdition return the number of Moments that have been 
    //                        minted from a certain edition.
    //
    // Parameters: setID: The id of the Set that is being searched
    //             playID: The id of the Play that is being searched
    //
    // Returns: The total number of Moments 
    //          that have been minted from an edition
    pub fun getNumMementosInEdition(deckID: UInt32, mementoID: UInt32): UInt32? {
        // Don't force a revert if the Set or play ID is invalid
        // Remove the Set from the dictionary to get its field
        if let deckToRead <- Toke.decks.remove(key: mementoID) {

            // Read the numMintedPerPlay
            let amount = deckToRead.numberMintedPerMemento[mementoID]

            // Put the Set back into the Sets dictionary
            Toke.decks[deckID] <-! deckToRead

            return amount
        } else {
            // If the set wasn't found return nil
            return nil
        }
    }


        // -----------------------------------------------------------------------
    // TopShot initialization function
    // -----------------------------------------------------------------------
    //
    init() {
        // Initialize contract fields
        self.mementoDatas = {}
        self.deckDatas = {}
        self.decks <- {}
        self.nextMementoID = 1
        self.nextDeckID = 1
        self.totalSupply = 0

        // Put a new Collection in storage
        self.account.save<@Collection>(<- create Collection(), to: /storage/MomentCollection)

        // Create a public capability for the Collection
        self.account.link<&{MementoCollectionPublic}>(/public/MomentCollection, target: /storage/MomentCollection)

        // Put the Minter in storage
        self.account.save<@Admin>(<- create Admin(), to: /storage/TokeAdmin)

        emit ContractInitialized()
    }

}
 