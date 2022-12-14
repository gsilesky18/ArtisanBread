//
//  Recipe.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 5/3/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import Foundation
import CoreData
@objc(Recipe)
class Recipe: NSManagedObject {

    @NSManaged var grams: String
    @NSManaged var ingredient: String
    @NSManaged var whichBread: Bread

}
