//
//  Bread.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 5/3/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import Foundation
import CoreData
@objc(Bread)
class Bread: NSManagedObject {

    @NSManaged var date: Date
    @NSManaged var name: String
    @NSManaged var notes: String
    @NSManaged var photo: Data
    @NSManaged var rating: String
    @NSManaged var scale: NSNumber
    @NSManaged var recipe: NSSet

}
