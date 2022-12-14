//
//  InstructionsDetailViewController.swift
//  Artisan Bread
//
//  Created by H Steve Silesky on 4/27/15.
//  Copyright (c) 2015 STEVE SILESKY. All rights reserved.
//

import UIKit
import WebKit

class InstructionsDetailViewController: UIViewController {
   //This code does not work in simulator
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Instructions"
        if let pdfURL = Bundle.main.url(forResource: "Instructions", withExtension: "pdf", subdirectory: nil, localization: nil)  {
            do {
                let data = try Data(contentsOf: pdfURL)
                let webView = WKWebView(frame: CGRect(x:20,y:20,width:view.frame.size.width-40, height:view.frame.size.height-40))
                webView.load(data, mimeType: "application/pdf", characterEncodingName:"", baseURL: pdfURL.deletingLastPathComponent())
                self.view.addSubview(webView)
            }
            catch {
                let error:NSError? = nil
                print("pdf loading error \(error!.userInfo)")
            }
        }
    }
}
