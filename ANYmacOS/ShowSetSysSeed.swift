//
//  About.swift
//  ANYmacOS
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa


class ShowSetSysSeed: NSViewController {
    
    @IBOutlet weak var copyright: NSTextField!
    @IBOutlet weak var version: NSTextField!

    override func viewDidAppear() {
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
        super.viewDidAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
}

    @IBAction func close_window(_ sender: Any) {
        self.view.window?.close()
    }
    
    @objc func cancel(_ sender: Any?) {
        self.view.window?.close()
    }
    
}
