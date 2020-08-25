import NonFungibleToken from 0x179b6b1cb6755e31

pub contract Toke : NonFungibleToken {
    // Emitted when a new Memento struct is created
    pub event MementoCreated(id: UInt32, metadata: {String:String})
    pub event ContractInitialized()

    // Events for Deck-Related actions
    //
    // Emitted when a deck is created
    pub event DeckCreated(deckID: UInt32)

    //pub event SpecialLootEventStarted(lootID:UInt32)
    // Emitted when a new special loot event is finished
    //pub event SpecialLootEventFinished(deckID: UInt32, mementoID: UInt32, nummementos: UInt32)
    // Emitted when a memento is minted
    pub event MementoMinted(NFTID: UInt64, mementoID: UInt32, deckID: UInt32)
    // Emitted when a memento can not be minted anymore
    pub event MementoRetiredFromDeck(deckID: UInt32, mementoID: UInt32, nummementos: UInt32)

    // Events for Collection-related actions
    //
    // Emitted when a memento is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)
    // Emitted when a memento is deposited into a Collection
    pub event Deposit(id: UInt64, to: Address?)

    pub event MementoAddedToDeck(deckID: UInt32, mementoID: UInt32)

    pub event DeckLocked(deckID: UInt32)

    // Emitted when a memento is destroyed
    pub event MementoDestroyed(id: UInt64)

    pub var totalSupply: UInt64


    pub struct Memento {

        pub let admin: &Admin
        // The unique ID for the memento
        pub let mementoID: UInt32

        // Store the Memento metadata
        //
        pub let metadata: {String: String}

        init(metadata: {String: String}, admin:&Admin) {
            pre {
                metadata.length != 0: "New memento metadata cannot be empty"
            }
            self.admin = admin as &Admin
            self.mementoID = self.admin.nextMementoID
            self.metadata = metadata
            emit MementoCreated(id: self.mementoID, metadata: metadata)
        }
    }


    pub struct DeckData {

        // Unique ID for the deck
        pub let deckID: UInt32

        // Name of the deck
        pub let name: String


        init(name: String, admin: &Admin) {
            pre {
                name.length > 0: "New deck name cannot be empty"
            }
            self.deckID = admin.nextDeckID
            self.name = name

            emit DeckCreated(deckID: self.deckID)
        }
    }



    // Admin can also retire Memento from the deck, meaning that the retired
    // deck can no longer mint this memento
    //
    // If the admin locks the deck, no more mementos can be added to it, but 
    // already minted mementos can still be minted.
    //
    // If retireAll() and lock() are called back-to-back, 
    // the deck is closed off forever and nothing more can be done with it.
    pub resource Deck {
        pub let admin: &Admin
        // Unique ID for the deck
        pub let deckID: UInt32

        pub let deckVisible: Bool

        // Array of mementos that are a part of this deck.
        // When a memento is added to the deck, its ID gets appended here.
        // The ID does not get removed from this array when a memento is retired.
        pub var mementos: [UInt32]

        // Map of memento IDs that Indicates if a memento in this deck can be minted.
        // When a memento is added to a deck, it is mapped to false (not retired).
        // When a memento is retired, this is deck to true and cannot be changed.
        pub var retired: {UInt32: Bool}

        // Indicates if the deck is currently locked.
        // When a deck is created, it is unlocked 
        // and mementos are allowed to be added to it.
        // When a deck is locked, mementos cannot be added.
        // A deck can never be changed from locked to unlocked,
        // the decision to lock a deck it is final.
        // If a deck is locked, mementos cannot be added, but
        // mementos can still be minted from mementos
        // that exist in the deck.
        pub var locked: Bool

        // Mapping of memento IDs that indicates the number of mementos 
        // that have been minted for specific mementos in this deck.
        // When a memento is minted, this value is stored in the memento to
        // show its place in the deck, eg. 13 of 60.
        pub var numberMintedPerMemento: {UInt32: UInt32}

        init(name: String, admin: &Admin) {
            self.admin = admin as &Admin
            self.deckID = self.admin.nextDeckID
            self.mementos = []
            self.deckVisible = false
            self.retired = {}
            self.locked = false
            self.numberMintedPerMemento = {}

            // Create a new deckData for this deck and store it in contract storage
            admin.deckDatas[self.deckID] = DeckData(name: name, admin: admin)
        }

        pub fun listMementosOfDeck(): [UInt32] {
            pre {
                !self.deckVisible : "Cannot list the mementos of this deck, the deck is deck a not public"
            }
            return self.mementos
        }


        pub fun unlockDeck(){
            self.locked = false

        }

        // addmemento adds a memento to the deck
        //
        // Parameters: mementoID: The ID of the memento that is being added
        //
        // Pre-Conditions:
        // The memento needs to be an existing memento
        // The deck needs to be not locked
        // The memento can't have already been added to the deck
        //
        pub fun addMemento(mementoID: UInt32) {
            pre {
                self.admin.mementoDatas[mementoID] != nil: "Cannot add the memento to deck: memento doesn't exist."
                !self.locked: "Cannot add the memento to the deck after the deck has been locked."
                self.numberMintedPerMemento[mementoID] == nil: "The memento has already beed added to the deck."
            }

            // Add the memento to the array of mementos
            self.mementos.append(mementoID)

            // Open the memento up for minting
            self.retired[mementoID] = false

            // Initialize the memento count to zero
            self.numberMintedPerMemento[mementoID] = 0

            emit MementoAddedToDeck(deckID: self.deckID, mementoID: mementoID)
        }

        // addmementos adds multiple mementos to the deck
        //
        // Parameters: mementoIDs: The IDs of the mementos that are being added
        //                      as an array
        //
        pub fun addMementos(mementoIDs: [UInt32]) {
            for memento in mementoIDs {
                self.addMemento(mementoID: memento)
            }
        }

        // retirememento retires a memento from the deck so that it can't mint new mementos
        //
        // Parameters: mementoID: The ID of the memento that is being retired
        //
        // Pre-Conditions:
        // The memento is part of the deck and not retired (available for minting).
        // 
        pub fun retireMemento(mementoID: UInt32) {
            pre {
                self.retired[mementoID] != nil: "Cannot retire the memento: memento doesn't exist in this deck!"
            }

            if !self.retired[mementoID]! {
                self.retired[mementoID] = true
                emit MementoRetiredFromDeck(deckID: self.deckID, mementoID: mementoID, nummementos: self.numberMintedPerMemento[mementoID]!)
            }
        }

        // retireAll retires all the mementos in the deck
        // Afterwards, none of the retired mementos will be able to mint new mementos
        //
        pub fun retireAll() {
            for memento in self.mementos {
                self.retireMemento(mementoID: memento)
            }
        }

        // lock() locks the deck so that no more mementos can be added to it
        //
        // Pre-Conditions:
        // The deck should not be locked
        pub fun lock() {
            if !self.locked {
                self.locked = true
                emit DeckLocked(deckID: self.deckID)
            }
        }

        // mintmemento mints a new memento and returns the newly minted memento
        // 
        // Parameters: mementoID: The ID of the memento that the memento references
        //
        // Pre-Conditions:
        // The memento must exist in the deck and be allowed to mint new mementos
        //
        // Returns: The NFT that was minted
        // 
        pub fun mintMemento(mementoID: UInt32, fanPoints: UInt64): @NFT {
            pre {
                self.retired[mementoID] != nil: "Cannot mint the memento: This memento doesn't exist."
                !self.retired[mementoID]!: "Cannot mint the memento from this memento: This memento has been retired."
            }

            // Gets the number of mementos that have been minted for this memento
            // to use as this memento's serial number
            let numInmemento = self.numberMintedPerMemento[mementoID]!

            // Mint the new memento
            let newmemento: @NFT <- create NFT(serialNumber: numInmemento + UInt32(1),
                                              mementoID: mementoID,
                                              deckID: self.deckID,fanPoints: fanPoints, admin: self.admin)

            // Increment the count of mementos minted for this memento
            self.numberMintedPerMemento[mementoID] = numInmemento + UInt32(1)

            return <-newmemento
        }

        // batchMintmemento mints an arbitrary quantity of mementos 
        // and returns them as a Collection
        //
        // Parameters: mementoID: the ID of the memento that the mementos are minted for
        //             quantity: The quantity of mementos to be minted
        //
        // Returns: Collection object that contains all the mementos that were minted
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

        destroy(){
        }
    }


    pub struct MementoData {

        // The ID of the deck that the memento comes from
        pub let deckID: UInt32

        // The ID of the memento that the memento references
        pub let mementoID: UInt32

        // The place in the edition that this memento was minted
        // Otherwise know as the serial number
        pub let serialNumber: UInt32

        init(deckID: UInt32, mementoID: UInt32, serialNumber: UInt32) {
            self.deckID = deckID
            self.mementoID = mementoID
            self.serialNumber = serialNumber
        }

    }


    // The resource that represents the memento NFTs
    //
    pub resource NFT: NonFungibleToken.INFT {

        // Global unique memento ID
        pub let id: UInt64
        pub let admin : &Admin
        // Struct of memento metadata
        pub let data: MementoData
        // Number of fanpoints fans will get when doing actions with their tokens
        pub var fanPoints: UInt64

        init(serialNumber: UInt32, mementoID: UInt32, deckID: UInt32, fanPoints: UInt64, admin: &Admin) {
            
            self.admin = admin as &Admin

            self.id = self.admin.totalSupply
            self.fanPoints = fanPoints

            // deck the metadata struct
            self.data = MementoData(deckID: deckID, mementoID: mementoID, serialNumber: serialNumber)

            emit MementoMinted(NFTID: self.id, mementoID: mementoID, deckID: self.data.deckID)
        }

        // If the memento is destroyed, emit an event to indicate 
        // to outside ovbservers that it has been destroyed
        destroy() {
            emit MementoDestroyed(id: self.id)
        }
    }

    // Admin is a special authorization resource that 
    // allows the owner to perform important functions to modify the 
    // various aspects of the mementos, decks, and mementos
    //
    pub resource Admin {
        // Variables
        // Variable size dictionary of memento structs
        pub var mementoDatas: {UInt32: Memento}

        // Variable size dictionary of deckData structs
        pub var deckDatas: {UInt32: DeckData}

        // Variable size dictionary of deck resources
        pub var decks: @{UInt32: Deck}

        // The ID that is used to create mementos. 
        // Every time a memento is created, mementoID is assigned 
        // to the new memento's ID and then is incremented by 1.
        pub var nextMementoID: UInt32

        // The ID that is used to create decks. Every time a deck is created
        // deckID is assigned to the new deck's ID and then is incremented by 1.
        pub var nextDeckID: UInt32

        // The total number of Top shot memento NFTs that have been created
        // Because NFTs can be destroyed, it doesn't necessarily mean that this
        // reflects the total number of NFTs in existence, just the number that
        // have been minted to date. Also used as global memento IDs for minting.
        pub var totalSupply: UInt64

        // creatememento creates a new memento struct 
        // and stores it in the mementos dictionary in the TopShot smart contract
        //
        // Parameters: metadata: A dictionary mapping metadata titles to their data
        //                       example: {"mementoer Name": "Kevin Durant", "Height": "7 feet"}
        //                               (because we all know Kevin Durant is not 6'9")
        //
        // Returns: the ID of the new memento object
        //
        pub fun createMemento(metadata: {String: String}) {

            // Create the new memento
            var newMemento = Memento(metadata: metadata, admin: &self as &Admin)

            // Store it in the contract storage
            self.mementoDatas[newMemento.mementoID] = newMemento
            // Increment the ID so that it isn't used again
            self.nextMementoID = self.nextMementoID + UInt32(1)
        }

        // createdeck creates a new deck resource and stores it
        // in the decks mapping in the TopShot contract
        //
        // Parameters: name: The name of the deck
        //
        pub fun createDeck(name: String) {
            // Create the new deck
            var newDeck <- create Deck(name: name, admin: &self as &Admin)

            // Store it in the decks mapping field
            self.decks[newDeck.deckID] <-! newDeck
            // Increment the deckID so that it isn't used again
            self.nextDeckID = self.nextDeckID + UInt32(1)
        }

        // getmementoMetaDataByField returns the metadata associated with a 
        //                        specific field of the metadata
        //                        Ex: field: "Team" will return something
        //                        like "Memphis Grizzlies"
        // 
        // Parameters: mementoID: The id of the memento that is being searched
        //             field: The field to search for
        //
        // Returns: The metadata field as a String Optional
        pub fun getMementoMetaDataByField(mementoID: UInt32, field: String): String? {
            // Don't force a revert if the mementoID or field is invalid
            if let memento = self.mementoDatas[mementoID] {
                return memento.metadata[field]
            } else {
                return nil
            }
        }

        
        // getmementoMetaData returns all the metadata associated with a specific memento
        // 
        // Parameters: mementoID: The id of the memento that is being searched
        //
        // Returns: The metadata as a String to String mapping optional
        pub fun getMementoMetaData(mementoID: UInt32): {String: String}? {
            return self.mementoDatas[mementoID]?.metadata
        }

        // borrowdeck returns a reference to a deck in the TopShot
        // contract so that the admin can call methods on it
        //
        // Parameters: deckID: The ID of the deck that you want to
        // get a reference to
        //
        // Returns: A reference to the deck with all of the fields
        // and methods exposed
        //
        pub fun borrowDeck(deckID: UInt32): &Deck {
            pre {
                self.decks[deckID] != nil: "Cannot borrow deck: The deck doesn't exist"
            }
            
            // Get a reference to the deck and return it
            // use `&` to indicate the reference to the object and type
            return &self.decks[deckID] as &Deck
        }

            
        // getdeckName returns the name that the specified deck
        //            is associated with.
        // 
        // Parameters: deckID: The id of the deck that is being searched
        //
        // Returns: The name of the deck
        pub fun getDeckName(deckID: UInt32): String? {
            // Don't force a revert if the deckID is invalid
            return self.deckDatas[deckID]?.name
        }

        // getdeckIDsByName returns the IDs that the specified deck name
        //                 is associated with.
        // 
        // Parameters: deckName: The name of the deck that is being searched
        //
        // Returns: An array of the IDs of the deck if it exists, or nil if doesn't
        pub fun getDeckIDsByName(deckName: String): [UInt32]? {
            var deckIDs: [UInt32] = []

            // Iterate through all the deckDatas and search for the name
            for deckData in self.deckDatas.values {
                if deckName == deckData.name {
                    // If the name is found, return the ID
                    deckIDs.append(deckData.deckID)
                }
            }

            // If the name isn't found, return nil
            // Don't force a revert if the deckName is invalid
            if deckIDs.length == 0 {
                return nil
            } else {
                return deckIDs
            }
        }
        // getmementosIndeck returns the list of memento IDs that are in the deck
        // 
        // Parameters: deckID: The id of the deck that is being searched
        //
        // Returns: An array of memento IDs
        pub fun getMementosInDeck(deckID: UInt32): [UInt32]? {
            // Don't force a revert if the deckID is invalid
            return self.decks[deckID]?.mementos
        }
        // isEditionRetired returns a boolean that indicates if a deck/memento combo
        //                  (otherwise known as an edition) is retired.
        //                  If an edition is retired, it still remains in the deck,
        //                  but mementos can no longer be minted from it.
        // 
        // Parameters: deckID: The id of the deck that is being searched
        //             mementoID: The id of the memento that is being searched
        //
        // Returns: Boolean indicating if the edition is retired or not
        pub fun isMementoRetired(deckID: UInt32, mementoID: UInt32): Bool? {
            // Don't force a revert if the deck or memento ID is invalid
            // Remove the deck from the dictionary to get its field
            if let deckToRead <- self.decks.remove(key: deckID) {

                // See if the memento is retired from this deck
                let retired = deckToRead.retired[mementoID]

                // Put the deck back in the contract storage
                self.decks[deckID] <-! deckToRead

                // Return the retired status
                return retired
            } else {

                // If the deck wasn't found, return nil
                return nil
            }
        }

        // isdeckLocked returns a boolean that indicates if a deck
        //             is locked. If it's locked, 
        //             new mementos can no longer be added to it,
        //             but mementos can still be minted from mementos the deck contains.
        // 
        // Parameters: deckID: The id of the deck that is being searched
        //
        // Returns: Boolean indicating if the deck is locked or not
        pub fun isDeckLocked(deckID: UInt32): Bool? {
            // Don't force a revert if the deckID is invalid
            return self.decks[deckID]?.locked
        }

            // getNummementosInEdition return the number of mementos that have been 
        //                        minted from a certain edition.
        //
        // Parameters: deckID: The id of the deck that is being searched
        //             mementoID: The id of the memento that is being searched
        //
        // Returns: The total number of mementos 
        //          that have been minted from an edition
        pub fun getNumMementosInEdition(deckID: UInt32, mementoID: UInt32): UInt32? {
            // Don't force a revert if the deck or memento ID is invalid
            // Remove the deck from the dictionary to get its field
            if let deckToRead <- self.decks.remove(key: mementoID) {

                // Read the numMintedPermemento
                let amount = deckToRead.numberMintedPerMemento[mementoID]

                // Put the deck back into the decks dictionary
                self.decks[deckID] <-! deckToRead

                return amount
            } else {
                // If the deck wasn't found return nil
                return nil
            }
        }

        // createNewAdmin creates a new Admin resource
        //
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }

        init(){ 
            self.mementoDatas = {}
            self.deckDatas = {}
            self.decks <- {}
            self.nextMementoID = 1
            self.nextDeckID = 1
            self.totalSupply = 0
        }
        destroy() {
            destroy self.decks
        }
        
    }   




    // This is the interface that users can cast their memento Collection as
    // to allow others to deposit mementos into their Collection. It also allows for reading
    // the IDs of mementos in the Collection.
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
                    "Cannot borrow memento reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection is a resource that every user who owns NFTs 
    // will store in their account to manage their NFTS
    //
    pub resource Collection: MementoCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic { 
        // Dictionary of memento conforming tokens
        // NFT is a resource type with a UInt64 ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        // withdraw removes an memento from the Collection and moves it to the caller
        //
        // Parameters: withdrawID: The ID of the NFT 
        // that is to be removed from the Collection
        //
        // returns: @NonFungibleToken.NFT the token that was withdrawn
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {

            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: withdrawID) as! @Toke.NFT?
                ?? panic("Cannot withdraw: memento does not exist in the collection")
            emit Withdraw(id: token.id, from: self.owner?.address)

            // Return the withdrawn token
            return <-token
        }

        // batchWithdraw withdraws multiple tokens and returns them as a Collection
        //
        // Parameters: ids: An array of IDs to withdraw
        //
        // Returns: @NonFungibleToken.Collection: A collection that contains
        //                                        the withdrawn mementos
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

        // deposit takes a memento and adds it to the Collections dictionary
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

        // borrowNFT Returns a borrowed reference to a memento in the Collection
        // so that the caller can read its ID
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        //
        // Note: This only allows the caller to read the ID of the NFT,
        // not any topshot specific data. Please use borrowmemento to 
        // read memento data.
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowmemento returns a borrowed reference to a memento
        // so that the caller can read data and call methods from it.
        // They can use this to read its deckID, mementoID, serialNumber,
        // or any of the deckData or memento data associated with it by
        // getting the deckID or mementoID and reading those fields from
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
    // mementos in transactions.
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <-create Toke.Collection()
    }

    //Create an admin for streamer to administrate their own mementos 
    pub fun createAdmin(): @Toke.Admin {
        return <- create Toke.Admin()
    }

    // -----------------------------------------------------------------------
    // TopShot initialization function
    // -----------------------------------------------------------------------
    //
    init() {
        self.totalSupply = 0
        emit ContractInitialized()

    }

}
 