//
//  Website.swift
//
//
//  Created by Prof. Dr. Luigi on 13.08.19.
//

import Cocoa
import WebKit

class Website: NSViewController {
    
    @IBOutlet weak var webView: WebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
        let url = NSURL (string: "https://www.sl-soft.de/extern/software/anymacos/anymacos.html")
        let requestObj = NSURLRequest(url: url! as URL)
        webView.mainFrame.load(requestObj as URLRequest)
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}
