//
//  BreadData.swift
//  Artisan iPhone
//
//  Created by H Steve Silesky on 8/3/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import Foundation
import CloudKit

class BreadData: NSObject {
    var record : CKRecord!
    var date : Date
    var datafile : Data
    weak var database : CKDatabase!
    init(record : CKRecord, database: CKDatabase){
        self.record = record
        self.database = database
        self.date = record.object(forKey: "date") as! Date
        self.datafile = (record.object(forKey: "datafile") as! Data?)!
    }
}
