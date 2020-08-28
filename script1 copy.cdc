      import FanCoin from 0xe03daebed8ca0615
      import Toke from 0xf3fcd2c1a78f5eee

      pub fun main(): {UInt32:String} {
                let acct = getAccount(0x120e725050340cab)
                let acctRef = acct.getCapability(/public/TokePublic)!
                                           .borrow<&{Toke.AdminPublic}>()!   
               log(acctRef.listMementos())            
                return acctRef.listMementos()
      }