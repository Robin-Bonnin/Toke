import Toke from 0xf3fcd2c1a78f5eee
transaction() {
    prepare(acct: AuthAccount) {

        // borrow a reference to the admin resource
        let admin = acct.borrow<&Toke.Admin>(from: /storage/TokeAdmin)
            ?? panic("No admin resource in storage")
        admin.createMemento(metadata: {"2":"2nd stuff"})

        log("Memento created")
    }
}