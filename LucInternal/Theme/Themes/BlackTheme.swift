/*
 

 

 
 */

import UIKit

@objcMembers
 public class  BlackTheme: DarkTheme {

    public override init() {
        super.init()
        self.backgroundColor = UIColor(rgb: 0x000000)
        self.baseColor = UIColor(rgb: 0x060708)
        self.headerBackgroundColor = UIColor(rgb: 0x090A0C)
        self.headerBorderColor = UIColor(rgb: 0x0D0F12)
    }
    
}
