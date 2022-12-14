//
//  Recipeext.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 4/4/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import Foundation
import CoreData

extension Recipe {
    
    struct Parameter {
    static let kPercentwaterloss = "percentWaterLoss"
    static let kIncludeHydration = "includeLeavenHydration"
    }

    class func
        loadIngredDict(_ dict: NSDictionary, theDate: Date, context: NSManagedObjectContext) -> Recipe {
            var recipe: Recipe!
            let ingredientArray = dict.allKeys as NSArray
            for theIngred in ingredientArray {
            recipe = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context) as! Recipe
            recipe.ingredient = theIngred as! String
            recipe.grams = dict.object(forKey: theIngred) as! String
            recipe.whichBread = Bread.breadWithDate(theDate, context: context)
            }
            return recipe
    }
    
    class func
        loadIngredDictForSample (_ dict: NSDictionary, theDate: Date, context: NSManagedObjectContext) -> Recipe {
            var recipe: Recipe!
            let ingredientArray = dict.object(forKey: "ingredients") as! NSArray
            for theIngred in ingredientArray  {
                recipe = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context) as! Recipe
                recipe.ingredient = (theIngred as! NSDictionary)["ingred"] as! String
                recipe.grams = (theIngred as! NSDictionary)["grams"]  as! String
                recipe.whichBread = Bread.breadWithDate(theDate, context: context)
                }
                return recipe
    }
    class func
        createRecipesForBread(_ breadDate: Date, scalingFactor: Float, context: NSManagedObjectContext ) -> NSDictionary {
            
            //read in user defaults
            //var recipe: Recipe!
            var noteStr:String = String()
            var rtnDict:Dictionary = [String: String]()
            let defaults = UserDefaults.standard
            let waterPercent:Float = defaults.float(forKey: Parameter.kPercentwaterloss)
            let useLeaven:Float = defaults.float(forKey: Parameter.kIncludeHydration)
            //select ingredients
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.entity = NSEntityDescription.entity(forEntityName: "Recipe", in: context) 
            let ingredientSortDescriptor = NSSortDescriptor(key: "ingredient", ascending: true)
            request.sortDescriptors = [ingredientSortDescriptor]
            let predicate = NSPredicate(format: "whichBread.date =%@", breadDate as CVarArg)
            request.predicate = predicate
            let objects = (try! context.fetch(request)) as! [Recipe]

            if objects.count == 0 {
                print("No Matches")
            }else{
                let tablelist = NSMutableString()
                let gramsList = NSMutableString()
                let percentlist = NSMutableString()
                let mailString = NSMutableString()
                
                //setup mailString heading
                mailString.append("<font size =\"1\" ><table cellspacing=\"5\" ><tr>")
                mailString.append("<td align=\"center\"><b>Ingredient</td>")
                mailString.append("<td align=\"center\"><b>Gr.</td>")
                mailString.append("<td align=\"center\"><b>%</b></td></tr>")
                
                
            var flour = Float()
            var total = Float()
            var water = Float()
            var leaven = Float()

            for recipe in objects {
                    if (recipe.ingredient as NSString).isEqual(to: "Leaven") {
                       leaven = (recipe.grams as NSString).floatValue * scalingFactor
                    }
                    if recipe.ingredient.hasSuffix("Flour")//all percentages calcuated as % of total flour
                    {
                        flour += (recipe.grams as NSString).floatValue * scalingFactor
                    }
                    if recipe.ingredient == "Water" // to adjust for water loss
                    {
                        water = (recipe.grams as NSString).floatValue * scalingFactor
                    }
                }
                water += 0.5 * leaven * useLeaven
                flour += 0.5 * leaven * useLeaven
                
                for recipe in objects {
                    //calc. total weight
                    total += (recipe.grams as NSString).floatValue * scalingFactor
                    //apply scaling factor
                    var grams = (recipe.grams as NSString).floatValue * scalingFactor
                    let strGrams =  NSString(format: "%.0f", grams)
                    //calculate percentages
                    if (recipe.ingredient as NSString).isEqual(to: "Water"){
                        grams = water
                    }
                    let strPercent = NSString(format: "%.1f", grams/flour * 100.0 )
                    //load strings with ingredients and values
                    tablelist.append(recipe.ingredient)
                    tablelist.append("\r\n")
                    gramsList.append(strGrams as String)
                    gramsList.append("\r\n")
                    percentlist.append(strPercent as String)
                    percentlist.append("\r\n")
                    //create HTML string for mail
                    mailString.append("<tr><td align=\"left\">")
                    mailString.append(recipe.ingredient)
                    mailString.append("</td><td align=\"right\">")
                    mailString.append(strGrams as String)
                    mailString.append("</td><td align=\"right\">")
                    mailString.append(strPercent as String)
                    mailString.append("</td></tr>")
                    noteStr = recipe.whichBread.notes
                }
                mailString.append("</tr></table>")
                //revise text style for notes
                mailString.append("<font size =\"3\" >")
                mailString.append("<br><b>Notes:</b>")
                mailString.append("<p> ")
                mailString.append(noteStr)
               
                
                //calculate bread lbs. (user defined water loss)
                let wl = NSString(format: "%.1f", (total - water * 0.01 * waterPercent)/453.5924)
                let weightLabel = wl.appending(" lbs. after baking")
                rtnDict ["tableList"] = tablelist as String
                rtnDict ["gramsList"] = gramsList as String
                rtnDict ["percentList"] = percentlist as String
                rtnDict ["weightLabel"] = weightLabel as String
                rtnDict ["mailString"] = mailString as String
              
            }
                return rtnDict as NSDictionary
        }

    }

