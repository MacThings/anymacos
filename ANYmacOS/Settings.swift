//
//  Settings.swift
//  ANYmacOS
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa

class Settings: NSViewController {

    @IBOutlet weak var download_path_textfield: NSTextFieldCell!
    @IBOutlet weak var image_path_textfield: NSTextField!

    let languageinit = UserDefaults.standard.string(forKey: "Language")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
    }

    @IBAction func set_download_path(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = NSLocalizedString("Choose a Folder", comment: "");
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["txt"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                download_path_textfield.stringValue = path
                let dlpath = (path as String)
                UserDefaults.standard.set(dlpath, forKey: "Downloadpath")
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    @IBAction func set_image_path(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = NSLocalizedString("Choose a Folder", comment: "");
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["txt"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                image_path_textfield.stringValue = path
                let dlpath = (path as String)
                UserDefaults.standard.set(dlpath, forKey: "Imagepath")
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
}
