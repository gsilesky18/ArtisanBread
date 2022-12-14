//
//  ImportExportExt.swift
//  Artisan iPhone
//
//  Created by H Steve Silesky on 7/28/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Bread {
    class func createDictForExport(_ context: NSManagedObjectContext) ->Data {
        let mainDict = NSMutableDictionary()
        var breadFile = Data()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Bread")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        let breads: [AnyObject]?
        do {
            breads = try context.fetch(request)
        } catch  {
            breads = nil
        }
        if (breads?.count == 0) {
            print("No Matches")
        }else{
            for bread:AnyObject in breads!//for each bread
            {
                //var properPhoto = NSData()
                let ingredArray = NSMutableArray()
                let array = Recipe.getIngredientsArray(bread as! Bread, context: context)
                for recipe in array //get ingredients for each bread
                {
                    let iDict  = ["ingredient": (recipe as! Recipe).ingredient, "grams": (recipe as! Recipe).grams] as NSDictionary
                    ingredArray.add(iDict)
                }
        //create dictionary for export
                let breadDict: NSDictionary = ["breadName":(bread as! Bread).name, "breadNotes":(bread as! Bread).notes, "breadDate":(bread as! Bread).date, "breadRating":(bread as! Bread).rating, "ingredArray":ingredArray]
                mainDict.setValue(breadDict, forKey: bread.name)
            }
        }
        //convert file to NSdata
        breadFile = try! PropertyListSerialization.data(fromPropertyList: mainDict, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
        return breadFile
    }
    
    class func importNewBreadRecipes(_ context: NSManagedObjectContext, breadDict: NSDictionary) {
    
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bread")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let breads:NSArray = try! context.fetch(fetchRequest) as NSArray
        if breads.count == 0 {
            for name  in breadDict.allKeys {
                let breadNameDict = breadDict.object(forKey: name as! NSString) as! NSDictionary
                var bread: Bread!
                bread = NSEntityDescription.insertNewObject(forEntityName: "Bread", into: context) as! Bread
                bread.name = breadNameDict["breadName"] as! String
                bread.notes = breadNameDict["breadNotes"] as! String
                bread.date = breadNameDict["breadDate"] as! Date
                bread.rating = breadNameDict["breadRating"] as! String
                //photo is not transferred so we use default
                bread.photo = UIImagePNGRepresentation(UIImage(named: "takePhoto.png")!)!
                Recipe.saveIngredientArray(breadNameDict, breadObject: bread, context: context)
            }
        }else {
            let newBreads:NSMutableDictionary = NSMutableDictionary()
            let existingBreads:NSMutableArray = NSMutableArray()
            for bread in breads {
                existingBreads.add((bread as! Bread).name) //array of all breads in app
            }
            for name in breadDict.allKeys {
                if !existingBreads.contains(name) {
                    let namedDict: AnyObject? = breadDict.object(forKey: name) as AnyObject?
                    newBreads.setValue(namedDict, forKey: name as! String)
                }
            }
            let importDict = newBreads
            for name  in importDict.allKeys {
                let breadNameDict = importDict.object(forKey: name as! NSString) as! NSDictionary
                var bread: Bread!
                bread = NSEntityDescription.insertNewObject(forEntityName: "Bread", into: context) as! Bread
                bread.name = breadNameDict["breadName"] as! String
                bread.notes = breadNameDict["breadNotes"] as! String
                bread.date = breadNameDict["breadDate"] as! Date
                bread.rating = breadNameDict["breadRating"] as! String
                //photo is not transferred so we use default
                bread.photo = UIImagePNGRepresentation(UIImage(named: "takePhoto.png")!)!
                Recipe.saveIngredientArray(breadNameDict, breadObject: bread, context: context)
            }
        }
    }
}

extension Recipe {

    class func getIngredientsArray(_ bread: Bread, context: NSManagedObjectContext) -> NSArray {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Recipe")
        let sortDescriptor = NSSortDescriptor(key: "ingredient", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        request.predicate = NSPredicate(format:"whichBread = %@", bread)
        let ingredients: [AnyObject]?
        do {
            ingredients = try context.fetch(request)
        } catch  {
            ingredients = nil
        }
        if ingredients?.count == 0 {
            print("No Matches")
        }
        return ingredients! as NSArray
    }
    class func saveIngredientArray(_ ingredDict: NSDictionary, breadObject:Bread, context: NSManagedObjectContext) {
        var recipe: Recipe!
        let ingredArray:NSArray = ingredDict["ingredArray"] as! NSArray
        for  ingred in ingredArray {
            recipe = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context) as! Recipe
            recipe.grams = (ingred as! NSDictionary)["grams"] as! String
            recipe.ingredient = (ingred as! NSDictionary)["ingredient"] as! String
            recipe.whichBread = breadObject
        }
    }
    
    
}
