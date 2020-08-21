import Toke from 0x179b6b1cb6755e31

// This transaction creates a new play struct 
// and stores it in the Top Shot smart contract
// We currently stringify the metadata and instert it into the 
// transaction string, but want to use transaction arguments soon

transaction() {
    prepare(acct: AuthAccount) {

        // borrow a reference to the admin resource
        let admin = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("No admin resource in storage")
        admin.createMemento(metadata: {"test":"testint"})
    }
}