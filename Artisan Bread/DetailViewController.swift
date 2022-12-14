//
//  DetailViewController.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 3/28/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData
import MessageUI
import MobileCoreServices


class DetailViewController: UIViewController,UIScrollViewDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var splashImageView: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var scalingLabel: UILabel!
    @IBOutlet weak var scalingResultsLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var percentTextView: UITextView!
    @IBOutlet weak var gramsTextView: UITextView!
    @IBOutlet weak var ingredientsTextView: UITextView!
    @IBOutlet weak var photoImageview: UIImageView!
    @IBOutlet weak var scalingSlider: UISlider!
    
    
    var imagePicker: UIImagePickerController!
    var ppc: UIPopoverPresentationController!
    var delegate: UIPopoverPresentationControllerDelegate?
    var breadDate = Date()
    var isSaving = false
    var viewDictionary = NSDictionary()
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //Notify after resetting user preferences
        NotificationCenter.default.addObserver(self, selector:#selector(DetailViewController.updateModel) , name: NSNotification.Name("UIApplicationWillEnterForegroundNotification"), object: nil)
        scalingSlider.value = 1.0
        self.setupFetch()
        self.createIngredientsText()
        coreDataStack.saveContext()
        isSaving = false
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(NSNotification.Name.UIApplicationDidBecomeActive)
    }
    //Selector for Notification Center
    @objc func updateModel(_ notification: Notification)
        {
        self.setupFetch()
        self.createIngredientsText()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Change color of back button chevron
        self.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        self.stepper.value = 0
        self.ratingLabel.text = "unrated"
        self.scalingLabel?.text = NSString(format: "%.2f", self.scalingSlider.value) as String
        let ca: CALayer = self.photoImageview.layer
        ca.masksToBounds = true
        ca.cornerRadius = 8.0
        notesTextView.layer.cornerRadius = 8.0
        
    }
    func createIngredientsText() {
        self.viewDictionary = Recipe.createRecipesForBread(self.breadDate, scalingFactor: self.scalingSlider.value, context: coreDataStack.managedObjectContext!)
        self.scalingResultsLabel.text = self.viewDictionary["weightLabel"] as? String
        self.ingredientsTextView.text = self.viewDictionary["tableList"] as? String
        self.gramsTextView.text = self.viewDictionary["gramsList"] as? String
        self.percentTextView.text = self.viewDictionary["percentList"] as? String
    }

    func setupFetch()
    {
        var bread: Bread!
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bread")
        request.fetchLimit = 50
        request.predicate = NSPredicate(format: "date = %@", self.breadDate as CVarArg)
        let fetchedResults = try! coreDataStack.managedObjectContext!.fetch(request)
        if fetchedResults.count == 0 {
            print("No Matches")
            splashImageView.isHidden = false
        }else{
            splashImageView.isHidden = true
            bread = fetchedResults.last as! Bread
            if self.isSaving == true {
                bread.notes = self.notesTextView.text!
                bread.rating = self.ratingLabel.text!
                bread.photo = UIImageJPEGRepresentation(photoImageview.image!, 0)!
                
            }else{
                if bread.rating.isEmpty {
                    self.ratingLabel.text = "unrated"
                }else{
                    self.ratingLabel.text = bread.rating
                }
                if !bread.notes.isEmpty {
                    self.notesTextView.text = bread.notes
                }
                photoImageview.image = UIImage(data: bread.photo)
                self.adjustStepper(bread.rating)
            }
        }
    }

    //MARK: - Save Data
    @IBAction func saveButton(_ sender: AnyObject) {
        //save notes, changes to rating, and photo
        self.isSaving = true
        self.setupFetch()
        self.createIngredientsText()
        coreDataStack.saveContext()
        self.notesTextView.resignFirstResponder()
        //show spinner while saving
        self.spinner.startAnimating()
        let delay = 0.8 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.spinner.stopAnimating()
        }
        self.isSaving = false
    }

    //MARK: - UIImagePickerController methods
    @IBAction func photoTapped(_ sender: UITapGestureRecognizer)
    {
        let alert = UIAlertController(title: "Choose Photo Source", message: "Take or Edit Photo Square", preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "Use Camera", style: UIAlertActionStyle.default, handler: { action in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
            {
                self.selectPhotoWith(UIImagePickerControllerSourceType.camera)
            }
        }))
        alert.addAction(UIAlertAction(title: "Use an Existing Photo", style: UIAlertActionStyle.default, handler: { action in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
            {
                self.selectPhotoWith(UIImagePickerControllerSourceType.photoLibrary)
            }
        }))
        
        alert.modalPresentationStyle = .popover
        ppc = alert.popoverPresentationController
        ppc.barButtonItem = self.saveButton
        
        present(alert, animated: true) { () -> Void in
            self.ppc.delegate = self
        }
    }
    
    func selectPhotoWith(_ sourceType: UIImagePickerControllerSourceType){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    //Converts to square image
    fileprivate func squareCropImageToSideLength(_ sourceImage: UIImage,
        sideLength: CGFloat) -> UIImage {
            // input size comes from image
            let inputSize: CGSize = sourceImage.size
            
            // round up side length to avoid fractional output size
            let sideLength: CGFloat = ceil(sideLength)
            
            // output size has sideLength for both dimensions
            let outputSize: CGSize = CGSize(width: sideLength, height: sideLength)
            
            // calculate scale so that smaller dimension fits sideLength
            let scale: CGFloat = max(sideLength / inputSize.width,
                sideLength / inputSize.height)
            
            // scaling the image with this scale results in this output size
            let scaledInputSize: CGSize = CGSize(width: inputSize.width * scale,
                height: inputSize.height * scale)
            
            // determine point in center of "canvas"
            let center: CGPoint = CGPoint(x: outputSize.width/2.0,
                y: outputSize.height/2.0)
            
            // calculate drawing rect relative to output Size
            let outputRect: CGRect = CGRect(x: center.x - scaledInputSize.width/2.0,
                y: center.y - scaledInputSize.height/2.0,
                width: scaledInputSize.width,
                height: scaledInputSize.height)
        
            
            // begin a new bitmap context, scale 0 takes display scale
            UIGraphicsBeginImageContextWithOptions(outputSize, true, 0)
        
            
            // optional: set the interpolation quality.
            // For this you need to grab the underlying CGContext
            let ctx: CGContext = UIGraphicsGetCurrentContext()!
            ctx.interpolationQuality = CGInterpolationQuality.high
            
            // draw the source image into the calculated rect
            sourceImage.draw(in: outputRect)
            
            // create new image from bitmap context
            let outImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            
            // clean up
            UIGraphicsEndImageContext()
            
            // pass back new image
        
            return outImage
    }
    
    //MARK: - UIImagePickerController delegates
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        let squareImage: UIImage = self.squareCropImageToSideLength(image!, sideLength: 300)
        photoImageview.image = squareImage
        isSaving = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    //MARK: - Stepper methods
    
    @IBAction func stepper(_ sender: AnyObject) {
        let rate:Double = sender.value
        switch (rate){
        case 1.0: self.ratingLabel.text = "★"
        case 2.0: self.ratingLabel.text = "★★"
        case 3.0: self.ratingLabel.text = "★★★"
        case 4.0: self.ratingLabel.text = "★★★★"
        case 5.0: self.ratingLabel.text = "★★★★★"
        default: self.ratingLabel.text = "unrated"
        }
    }
    func adjustStepper(_ rating: String) {
        let stars:Double = Double(rating.count)
        if stars > 5 {
            self.stepper.value = 0.0
        }else{
            self.stepper.value = stars
        }
    }
   
    //MARK: - Mail methods
    @IBAction func emailButton(_ sender: UIButton) {
       let mailComposeViewController = configuredMailComposeViewController(self.viewDictionary["mailString"]! as! String)
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController(_ textView: String) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        mailComposerVC.setSubject(self.title!)
        mailComposerVC.setMessageBody(textView, isHTML: true)
        
        return mailComposerVC
    }
    func showSendMailErrorAlert() {
        //let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: UIAlertControllerStyle.alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(sendMailErrorAlert, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: { print("mail sent") })
    }

    @IBAction func scalingSlider(_ sender: AnyObject) {
        self.scalingLabel?.text = NSString(format: "%.2f", self.scalingSlider.value) as String
        self.createIngredientsText()
    }
   
    //MARK: - ScrollView Delegates
    //Make sure columns are in sync
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.gramsTextView.contentOffset = self.ingredientsTextView.contentOffset
        self.percentTextView.contentOffset = self.ingredientsTextView.contentOffset
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageview
    }

    
}
//not currently used
extension UIImage {
    func resizeImage(newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    } }
