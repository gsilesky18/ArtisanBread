//
//  BreadViewController.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 1/13/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

let coreDataStack = CoreDataStack() //for instance of ManagedObjectContext as a singleton

//extension of to dismiss BreadViewController after cell selection
extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem
        UIApplication.shared.sendAction(barButtonItem.action!, to: barButtonItem.target, from: nil, for: nil)
    }
}

class BreadViewController: UIViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate, CloudKitDelegate {
    
    var detailedViewController: DetailViewController? = nil
  
   //Outlets
    
    @IBOutlet weak var exImButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmented: UISegmentedControl!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // Structs
    fileprivate struct Segments {
        static let kDate = 0
        static let kName = 1
        static let kRating = 2
    }

    //variables
    
    let reachability = Reachability()
    var mySearchString = String()
    
    var searchActive:Bool = false
    
    var _fetchedResultsController: NSFetchedResultsController<Bread>? = nil
    
    var fetchedResultsController: NSFetchedResultsController<Bread> {
        
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        let fRequest = fetchRequest()
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fRequest as! NSFetchRequest<Bread>, managedObjectContext: coreDataStack.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch  {
            
        }
        return  _fetchedResultsController!
    }
    
    //actions
    @IBAction func segmentChanged(_ sender: UISegmentedControl)
    {
        _fetchedResultsController = nil
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        self.tableView.reloadData()
        
    }
    let model : CloudKitHelper = CloudKitHelper.sharedInstance()
        override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.tintColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        let controllers = self.splitViewController!.viewControllers
        self.detailedViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? DetailViewController
        self.segmented.selectedSegmentIndex = 0
        title = "Breads"
        
        // load sample breads
        let numberBreads = self.fetchedResultsController.fetchedObjects
        if numberBreads?.count == 0 {
            let bundle = Bundle.main
            let plistURL = bundle.url(forResource: "Artisan", withExtension: "plist")
            var breadKeys:NSArray = [String]() as NSArray
            if let breadNames = NSDictionary(contentsOf: plistURL!){
                breadKeys = breadNames.allKeys as NSArray
                for breads in breadKeys {
                    let breadDict: AnyObject? = breadNames.value(forKey: breads as! String) as AnyObject?
                    let image = UIImage(named: "takePhoto.png")
                    let imageData = UIImagePNGRepresentation(image!)
                    Bread.loadSampleBreads(breadDict! as! NSDictionary, context: coreDataStack.managedObjectContext!, photo: imageData!)
                    let myDateFormat = DateFormatter()
                    let dateString = breadDict?.value(forKey: "date")
                    myDateFormat.dateFormat = "d LLLL yyyy HH:mm:ss"
                    let date = myDateFormat.date(from: dateString as! String)
                    let _ = Recipe.loadIngredDictForSample(breadDict! as! NSDictionary, theDate: date!, context: coreDataStack.managedObjectContext!)
                }
            coreDataStack.saveContext()
            }
        }
        searchBar.delegate = self
            model.delegate = self
            do {
                try fetchedResultsController.performFetch()
            } catch _ {
            }
    }
    // FetchRequest
       func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bread")
        fetchRequest.fetchBatchSize = 100
        let sortDescriptor = setSort()
        fetchRequest.sortDescriptors = [sortDescriptor]
        if searchActive == true {
            let predicate = NSPredicate(format: "name CONTAINS[c]%@", mySearchString )
            fetchRequest.predicate = predicate
            }
        return fetchRequest
    }
    //Sort
    func setSort() -> NSSortDescriptor {
        var sortDescriptor: NSSortDescriptor 
        switch self.segmented.selectedSegmentIndex {
            case Segments.kDate : sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            case Segments.kName : sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            case Segments.kRating : sortDescriptor = NSSortDescriptor(key: "rating", ascending: false)
        default: sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        }
        return sortDescriptor
    }
    
    
    //MARK: Methods to offer to write review
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let numberOfBeads = fetchedResultsController.fetchedObjects
        offerToWriteReview((numberOfBeads?.count)!)
    }
    //offers after addition of every 5th bread and if accepted after every 25th bread
    func offerToWriteReview(_ recipeNumber: Int) {
        let defaults = UserDefaults.standard
        let lastNumber:Int = defaults.integer(forKey: "lastNumber")
        if recipeNumber > lastNumber + 5 {
            let alert = UIAlertController(title: "Review this App?", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: {
                action in
                self.performSegue(withIdentifier: "toItunes", sender: nil)
                defaults.set(lastNumber + 25, forKey: "lastNumber")
            }))
            alert.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.default, handler: {
                action in
                defaults.set(recipeNumber, forKey: "lastNumber")
            }))
            present(alert, animated: true, completion: nil)
        }
    }

    //MARK: ImportExport methods
    
    @IBAction func exportImport(_ sender: UIBarButtonItem){
        
        let isConnected = reachability.isConnectedToNetwork()
        if isConnected == false {
            let alert = UIAlertController(title: "There is no network connectivity", message: "Try again later", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            present(alert, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Export/Import", message: "Tap Your Selection", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.addAction(UIAlertAction(title: "Import", style: UIAlertActionStyle.default, handler: {
                action in //Import from Cloud
                self.spinner.startAnimating()
                cloudKitHelper.addNewRecords(coreDataStack.managedObjectContext!)
            }))
            
            alert.addAction(UIAlertAction(title: "Export", style: UIAlertActionStyle.default, handler: {
                action in  //export to Cloud
                self.spinner.startAnimating()
                self.createDataForExport()
            }))
            alert.view.tintColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
            if let presenter = alert.popoverPresentationController {
                presenter.barButtonItem = exImButton
                presenter.permittedArrowDirections = UIPopoverArrowDirection.any
            }
            present(alert, animated: true, completion: nil)
        }
    }
    
    func createDataForExport()
    {
        let recipeFile:Data = Bread.createDictForExport(coreDataStack.managedObjectContext!)
        cloudKitHelper.saveRecord(recipeFile)
        
    }
        //MARK: CloudHelper delegate methods
    func modelUpdated() {
        print("model updated")
        DispatchQueue.main.async(execute: {
            self.spinner.stopAnimating()
            self.tableView.reloadData()
            coreDataStack.saveContext()
        })
        
    }
    func errorUpdating(_ error: NSError) {
        let message = error.localizedDescription
        let alert = UIAlertController(title: "Error loading Data", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func noFiletoImport() {
        self.spinner.stopAnimating()
        let alert = UIAlertController(title: "No file to import", message: "Export first!", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    //MARK: UITableView source and delegate methods
   @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberBreads = self.fetchedResultsController.fetchedObjects
        return numberBreads!.count
    }
    
   @objc func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BreadCell")
        let bread = self.fetchedResultsController.object(at: indexPath)
        cell!.textLabel?.text = bread.name
        // Place date and rating in cell
        let myDateFormat = DateFormatter()
        myDateFormat.dateStyle = (DateFormatter.Style.medium)
        myDateFormat.dateFormat = " LLL d, yyyy "
        let enterDate = myDateFormat.string(from: bread.date)
        let breadRating = bread.rating
        if !breadRating.isEmpty && breadRating != "unrated"
        {
            let rating = " " + (breadRating as String)
            var subtitle = NSAttributedString()
            subtitle = self.createdattributedStringForSubtitle(enterDate, rating: rating)
            cell!.detailTextLabel?.attributedText  = subtitle
        }else{
            cell!.detailTextLabel?.text = enterDate + " Unrated"
            cell!.detailTextLabel?.textColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        }
        return cell!
    }
    
   @objc func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        mySearchString = ""
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
   @objc func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
   @objc func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete
        {
            let bread = self.fetchedResultsController.object(at: indexPath)
            //remove bread object
            self.fetchedResultsController.managedObjectContext.delete(bread)
            coreDataStack.saveContext()
        }
    }
    //Adjust fonts and color for subtitle
    func createdattributedStringForSubtitle(_ theDate: String, rating: String) -> NSAttributedString {
        let rFont = UIFont(name: "Helvetica", size: 16.0) ?? UIFont.systemFont(ofSize: 16.0)
        let ratingFont = [NSAttributedStringKey.font:rFont]
        let tColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        let totalColor = [NSAttributedStringKey.foregroundColor:tColor]
        let dFont = UIFont(name: "helvetica Neue", size: 13.0) ?? UIFont.systemFont(ofSize: 13.0)
        let dateFont = [NSAttributedStringKey.font:dFont]
        let cellString = NSMutableAttributedString()
        let strDate = NSMutableAttributedString(string: theDate, attributes: dateFont)
        strDate.addAttributes(totalColor, range:NSMakeRange(0, strDate.length) )
        let strRating = NSMutableAttributedString(string: rating, attributes: ratingFont)
        strRating.addAttributes(totalColor, range: NSMakeRange(0, strRating.length))
        cellString.append(strDate)
        cellString.append(strRating)
        return cellString
    }
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch(type) {
            
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath],
                    with:UITableViewRowAnimation.fade)
            }
            
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath],
                    with: UITableViewRowAnimation.fade)
            }
            
        case .update:
            
        self.tableView.reloadData()
            
        case .move:
            if let indexPath = indexPath {
                if let newIndexPath = newIndexPath {
                    tableView.deleteRows(at: [indexPath],
                        with: UITableViewRowAnimation.fade)
                    tableView.insertRows(at: [newIndexPath],
                        with: UITableViewRowAnimation.fade)
                }
            }
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType)
    {
        switch(type) {
            
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // MARK: SearchController delegate methods
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
        searchBar.resignFirstResponder()
        _fetchedResultsController = nil
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        mySearchString = ""
        searchBar.text = ""
        _fetchedResultsController = nil
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        mySearchString = searchText
        searchActive = true
        _fetchedResultsController = nil
        do {
            try fetchedResultsController.performFetch()
        } catch  {
        }
        self.tableView.reloadData()
        }
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if let identifier = segue.identifier{
            switch identifier {
            case "toNewBread" : var destination = segue.destination
                if let navCon = destination as? UINavigationController{
                destination = navCon.visibleViewController!
                }
                if let nbc = destination as? NewBreadViewController{
                    nbc.isRevising = false
                }
            case "toEdit" : var destination = segue.destination
            if let navCon = destination as? UINavigationController{
                destination = navCon.visibleViewController!
            }
            if let nbc = destination as? NewBreadViewController{
                nbc.isRevising = true
                var indexPath = IndexPath()
                indexPath = self.tableView.indexPath(for: sender as! UITableViewCell)!
                let bread = self.fetchedResultsController.object(at: indexPath)
                nbc.name = bread.name
                nbc.breadDate = bread.date
                }
            case "toDetail" :
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let bread = self.fetchedResultsController.object(at: indexPath)
                var destination = segue.destination
                if let navCon = destination as? UINavigationController{
                    destination = navCon.visibleViewController!
                    }
                if let nbc = destination as? DetailViewController{
                nbc.title = bread.name
                nbc.breadDate = bread.date
                nbc.isSaving = false
                nbc.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                nbc.navigationItem.leftItemsSupplementBackButton = true
                self.splitViewController?.toggleMasterView()
                    }
                }
            default: break
            }
        }
    }
   
    }


