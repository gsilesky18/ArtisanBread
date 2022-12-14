//
//  Breadext.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 1/17/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//
import CoreData

extension Bread {
    
    //save new bread
    class func insertBread(_ breadName: String, breadDate: Date, context: NSManagedObjectContext, photo: Data){
        var bread: Bread!
        bread = NSEntityDescription.insertNewObject(forEntityName: "Bread", into: context) as! Bread
        bread.name = breadName
        bread.date = breadDate
        bread.rating = ""
        bread.notes = ""
        bread.photo = photo
    }
    
    //prepopulate sample breads
    class func loadSampleBreads(_ dict: NSDictionary, context: NSManagedObjectContext, photo: Data) {
        let myDateFormat = DateFormatter()
        let bread = NSEntityDescription.insertNewObject(forEntityName: "Bread", into: context) as! Bread
        bread.name = dict["name"] as! String
        bread.rating = dict["rating"] as! String
        bread.notes = dict["notes"] as! String
        bread.photo = photo
        bread.scale = NSNumber(value: 1.0 as Float)
        let dateString = dict["date"] as! String
        myDateFormat.dateFormat = "d LLLL yyyy HH:mm:ss"
        if let myDate = myDateFormat.date(from: dateString) {
            bread.date = myDate
        }
    }

    //whichBread
    class func
        breadWithDate (_ theDate: Date, context: NSManagedObjectContext) -> Bread {
            var bread: Bread!
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bread")
            request.predicate = NSPredicate(format: "date = %@", theDate as CVarArg)
            let breads = try? context.fetch(request)
            bread = breads?.last as! Bread
            return bread
    }
    
    class func breadwithName (_ theName:String, context:NSManagedObjectContext) -> Bread
    {
        var bread: Bread!
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bread")
        request.predicate = NSPredicate(format: "name = %@", theName)
        let breads: [AnyObject]?
        do {
            breads = try context.fetch(request)
        } catch  {
            breads = nil
        }
        bread = breads?[0] as! Bread
        return bread
    }

}
