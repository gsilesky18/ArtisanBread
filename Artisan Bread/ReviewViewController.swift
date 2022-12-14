//
//  ReviewViewController.swift
//  Artisan Bread for the iPhone
//
//  Created by H Steve Silesky on 7/2/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import UIKit

class ReviewViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let requestURL = URL(string:"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=993444714")
        let request = URLRequest(url: requestURL!)
         webView.loadRequest(request)
        NotificationCenter.default.addObserver(self, selector:#selector(ReviewViewController.popView(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
    
    //Selector for Notification Center
    @objc func popView(_ notification: Notification)
    {
        NotificationCenter.default.removeObserver(NSNotification.Name.UIApplicationDidBecomeActive)
        dismiss(animated: true, completion: nil)
    }

}

