//
//  About.swift
//  ANYmacOS
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa


class AppHelp: NSViewController {
    
    
    override func viewDidAppear() {
        self.view.window?.title = NSLocalizedString("Help", comment: "")
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

}

    @objc func cancel(_ sender: Any?) {
        self.view.window?.close()
    }
    
}
