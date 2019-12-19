//
//  FileSearchDataSource.swift
//  Luc
//
//  Created by HARSH VARDHAN on 30/10/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

@objcMembers class FileSearchDataSource: MXKSearchDataSource {
    
    
    override func searchMessages(_ textPattern: String!, force: Bool) {
        
        super.searchMessages(textPattern, force: force)
        //self.paginateBack()
        
        //super.state = MXKDataSourceStateReady;
        
        // Provide changes information to the delegate
//        let insertedIndexes:NSIndexSet = NSIndexSet(indexesIn: NSMakeRange(0, 5))
//        self.delegate.dataSource(self, didCellChange: insertedIndexes)
        
        
        
        
        
    }
}
