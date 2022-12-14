//
//  NewIngredientViewController.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 4/18/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import UIKit

class NewIngredientViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var saveNewIngred: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var ingredTextField: UITextField!
    var ingredients = [String]()

    func dataPath() ->String //dataPath for ingredients
    {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths[0]
        let dataPath = (documentsDirectory.appending("/ingredients.plist"))
        return dataPath
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if FileManager.default.fileExists(atPath: self.dataPath() as String){
            let myStoredIngred = NSArray(contentsOfFile: self.dataPath() as String)
            self.ingredients = myStoredIngred! as! [String]
        }
    }

    @IBAction func save(_ sender: UIButton) {
        if self.ingredTextField.text!.isEmpty //if bread name blank
        {
            let alert = UIAlertController(title: "Ingredient Required", message: "Enter a Name", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.modalPresentationStyle = .popover
            let ppc = alert.popoverPresentationController
            ppc?.sourceView = self.saveNewIngred
            present(alert, animated: true, completion: nil)
            return
        }
        let wordCount = self.ingredTextField.text!.count
        if wordCount > 19 //check for ingredient names that are too long
        {
            let alert = UIAlertController(title: "Name too long", message: "Enter less than 20 characters", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.modalPresentationStyle = .popover
            let ppc = alert.popoverPresentationController
            ppc?.sourceView = self.saveNewIngred
            present(alert, animated: true, completion: nil)
            ingredTextField.text = ""
            return
        }

        
        self.ingredients.append(self.ingredTextField.text!.capitalized)
        let sortedArray = self.ingredients.sorted { $0.localizedCaseInsensitiveCompare($1 as String ) == ComparisonResult.orderedAscending }
        self.ingredients = sortedArray
        self.ingredTextField.text = ""
        self.ingredTextField .resignFirstResponder()
        self.tableView.reloadData()
        (self.ingredients as NSArray).write(toFile: self.dataPath() as String, atomically: true)
        self.performSegue(withIdentifier: "BacktoNewBread", sender: self)
    }
    
    // MARK: - TableView dataSource and delegate
    
   @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Ingredients"
    }
    
   @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.ingredients.count
    }
    
    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ingredientCell", for: indexPath) 
        cell.textLabel?.text = self.ingredients[indexPath.row]
        return cell
    }
   @objc func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
   @objc func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete
        {
            self.ingredients.remove(at: indexPath.row)
            (self.ingredients as NSArray).write(toFile: self.dataPath() as String, atomically: true)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            self.performSegue(withIdentifier: "BacktoNewBread", sender: self) //update picker
        }
    }

    // MARK: - TextField Delegates
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        
    }

}
