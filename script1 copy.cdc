      import FanCoin from 0xe03daebed8ca0615
      import Toke from 0xf3fcd2c1a78f5eee

      pub fun main(): [UInt64] {
                let acct = getAccount(0xf669cb8d41ce0c74)
                let acctRef = acct.getCapability(/public/TokeCollection)!.borrow<&{Toke.MementoCollectionPublic}>()
                return acctRef.listNFTs()      
                }
 