//
//  NewBreadViewController.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 1/14/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

class NewBreadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIPopoverControllerDelegate {

    struct Tags {
        let kGramsButton = 0 
    }
    
    var name: String = String()
    var ppc: UIPopoverPresentationController!
    var delegate: UIPopoverPresentationControllerDelegate?
    var isRevising: Bool = Bool()
    var ingredients = [String]()
    var breadIngredients = [String:String]()
    var breadDate = Date()
    var sortedList:[String] = [String]()
    
    @IBOutlet weak var saveBread: UIBarButtonItem!
    @IBOutlet weak var addItemButton: UIButton!
    @IBOutlet weak var gramsButton: UIButton!
    @IBOutlet weak var gramsTextField: UITextField!
    @IBOutlet weak var breadNameTextField: UITextField!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var amountLabel: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addItem(_ sender: UIButton)
    {
        if self.ingredients.count < 1
        {
            let alert = UIAlertController(title: "No Ingredients Available", message: "First Define Ingredieents", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.modalPresentationStyle = .popover
            let ppc = alert.popoverPresentationController
            let viewTag = Tags()
            ppc?.sourceView = gramsButton.viewWithTag(viewTag.kGramsButton)
            present(alert, animated: true, completion: nil)
            return
            
        }
        if self.gramsTextField.text!.isEmpty {
            let alert = UIAlertController(title: "Grams Field Empty", message: "Enter Number of Grams", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.modalPresentationStyle = .popover
            let ppc = alert.popoverPresentationController
            let viewTag = Tags()
            ppc?.sourceView = gramsButton.viewWithTag(viewTag.kGramsButton)
            present(alert, animated: true, completion: nil)
            return
        }
        let item = self.ingredients[self.picker.selectedRow(inComponent: 0)]
        self.breadIngredients[item] = self.gramsTextField.text
        let iArray = self.breadIngredients.keys
        let iSorted = iArray.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
        self.sortedList = iSorted
        self.gramsTextField.text = ""
        self.gramsTextField.resignFirstResponder()
        self.tableView.reloadData()
        
    }
    
    @IBAction func SaveBread(_ sender: UIBarButtonItem)
    {
        //not editing - new bread
        if self.isRevising == false{
           if self.breadNameTextField.text!.isEmpty //if bread name blank
           {
            let alert = UIAlertController(title: "Bread Name Required", message: "Enter a Name", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.modalPresentationStyle = .popover
            let ppc = alert.popoverPresentationController
            ppc?.barButtonItem = saveBread
            present(alert, animated: true, completion: nil)
            return
            }
            
            let name = self.breadNameTextField.text
            self.recipeIntoDatabase(name!)
            breadNameTextField.text = ""
            breadIngredients.removeAll()
            self.dismiss(animated: true, completion: nil)
            
        }else //is Editing
        {
            self.deleteExistingIngredients(self.breadDate)
            let _ = Recipe.loadIngredDict(self.breadIngredients as NSDictionary, theDate: self.breadDate, context: coreDataStack.managedObjectContext!)
            self.breadNameTextField.text = ""
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func CancelAction(_ sender: UIBarButtonItem)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    func dataPath() ->NSString //dataPath for ingredients
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory: AnyObject = paths[0] as AnyObject
        let dataPath = documentsDirectory.appending("/ingredients.plist")
        return dataPath as NSString
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if FileManager.default.fileExists(atPath: self.dataPath() as String){
            let myStoredIngred = NSArray(contentsOfFile: self.dataPath() as String)
            self.ingredients = myStoredIngred! as! [String]
            
        }else{
            //prepopulate and sort PickerView
            let unsortedArray = [ "Water", "All Purpose Flour", "Leaven", "Salt", "Rye Flour", "Whole Wheat Flour", "Bread Flour", "Caraway Seeds" ]
            self.ingredients = unsortedArray.sorted {$0 < $1} 
            (self.ingredients as NSArray).write(toFile: self.dataPath() as String, atomically: true)
        }
        if self.isRevising == true //editing
        {
            
            let alert = UIAlertController(title: "Select Edit Type", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.addAction(UIAlertAction(title: "Edit the Existing Recipe", style: UIAlertActionStyle.default, handler: { action in
                self.breadNameTextField.isEnabled = false
                self.breadNameTextField.text = self.name
                self.createEditingTableView()
            }))
            
            alert.addAction(UIAlertAction(title: "New Bread from Existing Recipe", style: UIAlertActionStyle.default, handler: { action in
                self.isRevising = false
                self.breadNameTextField.isEnabled = true
                self.createEditingTableView()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
            
            alert.view.tintColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
            alert.modalPresentationStyle = .popover
            self.ppc = alert.popoverPresentationController
            self.ppc.sourceView = self.addItemButton
            
            present(alert, animated: true, completion: { () -> Void in
                self.ppc.delegate = self
            })
        }
        picker.reloadComponent(0) //refresh picker
        picker.selectRow(self.ingredients.count/2, inComponent: 0, animated: true) //set picker position
        let ca: CALayer = self.picker.layer
        ca.masksToBounds = true
        ca.cornerRadius = 8.0
        
    }
    
    func createEditingTableView() //ingredients currently used
    {
        let ingredDict = self.fetchExistingIngredients(self.name)
        let ingredArray = ingredDict.allKeys
        let iSorted = ingredArray.sorted { ($0 as AnyObject).localizedCaseInsensitiveCompare($1 as! String ) == ComparisonResult.orderedAscending }
        self.sortedList = iSorted as! [String]
        self.tableView.reloadData()
    }
    // when revising
    func fetchExistingIngredients(_ breadName:String) -> NSDictionary {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        request.fetchLimit = 50
        request.predicate = NSPredicate(format: "whichBread.date = %@", self.breadDate as CVarArg)
        let fetchedResults = try! coreDataStack.managedObjectContext!.fetch(request)
        if fetchedResults.count == 0 {
            print("No Matches")
        }else{
            for object in fetchedResults
            {
                let thisIngredient:String = (object as! Recipe).ingredient
                let amountInGrams:String = (object as! Recipe).grams
                self.breadIngredients [thisIngredient] = amountInGrams
            }
        }
        return self.breadIngredients as NSDictionary
    }
    
    func deleteExistingIngredients(_ theDate: Date) //update bread
    {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "whichBread.date = %@", theDate as CVarArg)
        let fetchedResults = try! coreDataStack.managedObjectContext!.fetch(request)
        if fetchedResults.count == 0 {
            print("No Matches")
        }else{
            for recipe in fetchedResults
            {
                coreDataStack.managedObjectContext?.delete(recipe as! NSManagedObject)
            }
        }
        
    }
    func recipeIntoDatabase(_ breadName: String)
    {
        let insertionDate = Date()
        let image = UIImage(named: "takePhoto.png")
        let imageData = UIImagePNGRepresentation(image!) 
        Bread.insertBread(breadName, breadDate:insertionDate, context: coreDataStack.managedObjectContext!, photo: imageData!)
        if !self.breadIngredients.isEmpty{
        let _ = Recipe.loadIngredDict(self.breadIngredients as NSDictionary, theDate: insertionDate, context: coreDataStack.managedObjectContext!)
        }
        coreDataStack.saveContext()
    }
    //rewind function from New Ingredient Controller
    @IBAction func updateIngredientsInPicker (_ segue: UIStoryboardSegue) {
        if FileManager.default.fileExists(atPath: self.dataPath() as String){
            let myStoredIngred = NSArray(contentsOfFile: self.dataPath() as String)
            self.ingredients = myStoredIngred! as! [String]}
        self.picker.reloadAllComponents()
    }
    @IBAction func addNewIngredient(_ sender: UIButton) {
        let alert = UIAlertController(title: "New Ingredient", message: "Add a new ingredient", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
            action in
            let textfield = (alert.textFields?[0])! as UITextField
            self.ingredients.append(textfield.text!)
            let sortedArray = self.ingredients.sorted { $0 < $1 }
            self.ingredients = sortedArray
            (self.ingredients as NSArray).write(toFile: self.dataPath() as String, atomically: true)
            self.picker.reloadAllComponents()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addTextField(configurationHandler: { (textField: UITextField!) -> Void
            in
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .no
            textField.becomeFirstResponder()
        })
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.view.tintColor = UIColor(red: 120/255, green: 44/255, blue: 44/255, alpha: 1.0)
        present(alert, animated: true, completion: nil)
    }
    
    //remove ingredient from picker with taps
    @IBAction func deleteIngredient(_ sender: UITapGestureRecognizer) {
        let item: AnyObject = ingredients[self.picker.selectedRow(inComponent: 0)] as AnyObject
        let alert = UIAlertController(title: "Ingredient Deletion", message: (item as! String) + " will be deleted", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: {
            action in
            self.ingredients.remove(at: self.picker.selectedRow(inComponent: 0))
            let sortedArray = self.ingredients.sorted { $0 < $1 }
            self.ingredients = sortedArray
            (self.ingredients as NSArray).write(toFile: self.dataPath() as String, atomically: true)
            self.picker.reloadAllComponents()
        })
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        alert.view.tintColor = UIColor(red: 120/255, green: 44/255, blue: 44/255, alpha: 1.0)
        present(alert, animated: true, completion: nil)
    }

    
    
    
    // MARK: - TableView dataSource and delegate
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Ingredients"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.breadIngredients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) 
        cell.textLabel?.text = self.sortedList[indexPath.row];
        let selectedIngredient = self.breadIngredients[cell.textLabel!.text!]
        cell.detailTextLabel?.text = (selectedIngredient)! + " Grams "
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete
        {
            self.breadIngredients.removeValue(forKey: self.sortedList[indexPath.row])
            self.sortedList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
    }
    // MARK: - PickerView DataSource and Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.ingredients.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.ingredients[row] 
        
    }
    
    // MARK: - TextField Delegates
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == gramsTextField{
            if (string == "0" ||  string == "1" || string == "2" || string == "3" || string == "4" || string == "5" || string == "6" || string == "7" || string == "8" || string == "9" ) || string.count == 0 {
                return true
            }else{
                return false
            }
        }
        return true
    }

    // MARK: - PopOverPresentationController Delegate Methods
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        if popoverPresentationController == self.ppc
        {
           return false
        }else{
        return true
        }
    }

    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){

            }


}
