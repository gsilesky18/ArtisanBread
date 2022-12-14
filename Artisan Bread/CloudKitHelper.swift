//
//  CloudKitHelper.swift
//  Artisan iPhone
//
//  Created by H Steve Silesky on 8/3/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

protocol CloudKitDelegate {
    func errorUpdating(_ error: NSError)
    func modelUpdated()
    func noFiletoImport()
}
let cloudKitHelper = CloudKitHelper()

class CloudKitHelper {
    var container : CKContainer
    var privateDB : CKDatabase
    var delegate : CloudKitDelegate?
    
    
    class func sharedInstance() -> CloudKitHelper{
        return cloudKitHelper
    }
    init() {
        container = CKContainer(identifier: "iCloud.com.zanysocksapps.Bread.SharedExIm")
        privateDB = container.privateCloudDatabase
    }
    //Export function
    func saveRecord(_ dataFile: Data) {
        let size = dataFile.count
        print("\(size)")
        let dataFileRecord = CKRecord(recordType: "BreadData")
        dataFileRecord.setValue(dataFile, forKey: "datafile")
        dataFileRecord.setValue(Date(), forKey: "date")
        privateDB.save(dataFileRecord, completionHandler: { (record, error) -> Void in
            if error == nil {
            self.delegate?.modelUpdated()
            print("saved to cloudkit")
            }else{
                let message = error!.localizedDescription
                print("\(message)")
            }
        })
    }
    //Import function
    func addNewRecords(_ context: NSManagedObjectContext) {
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "date", ascending:true)
        let query = CKQuery(recordType: "BreadData", predicate: predicate)
        query.sortDescriptors = [sort]
        privateDB.perform(query, inZoneWith: nil) { results, error in
            if results!.count == 0 {
                DispatchQueue.main.async {
                    self.delegate?.noFiletoImport()
                }
            }else if error != nil && results!.count != 0 {
                    DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error! as NSError)
                }
                
                }else {
                    let datafiles = BreadData(record: results!.last! as CKRecord, database: self.privateDB)
                    let data = datafiles.datafile
                    print("\(data.count)")
                    let dict: NSDictionary = (try! PropertyListSerialization.propertyList(from: data as Data, options: PropertyListSerialization.MutabilityOptions.mutableContainersAndLeaves, format: nil)) as! NSDictionary
                    Bread.importNewBreadRecipes(context, breadDict: dict)
                    let currentRecord = datafiles.record
                    self.privateDB.delete(withRecordID: (currentRecord?.recordID)!, completionHandler: { (recordID, error) -> Void in
                    print(error ?? "error deleting record")
                })
                    DispatchQueue.main.async {
                        self.delegate?.modelUpdated()
                    }
            }
        }
    }
}
