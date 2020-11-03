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
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);

        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_initial"])
            self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])
        }
        
        let seedinit = UserDefaults.standard.string(forKey: "CurrentSeed")
       

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
    
    @IBAction func seed_select(_ sender: Any) {
        let seedselect = (sender as AnyObject).selectedCell()!.tag
        if seedselect == 1 {
            UserDefaults.standard.set("Customer", forKey: "NewSeed")
        } else if seedselect == 2 {
            UserDefaults.standard.set("Developer", forKey: "NewSeed")
        } else if seedselect == 3 {
            UserDefaults.standard.set("Public", forKey: "NewSeed")
        } else if seedselect == 4 {
            UserDefaults.standard.set("Unenroll", forKey: "NewSeed")
        } else {
            return
        }
        
        //self.output_window.textStorage?.mutableString.setString("")
        
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_setseed"])
            
            DispatchQueue.main.sync {
                let seedinit = UserDefaults.standard.string(forKey: "CurrentSeed")
                                
            }
        }
    }
    
    func syncShellExec(path: String, args: [String] = []) {
        let process            = Process()
        process.launchPath     = "/bin/bash"
        process.arguments      = [path] + args
        let outputPipe         = Pipe()
        let filelHandler       = outputPipe.fileHandleForReading
        process.standardOutput = outputPipe
        process.launch()
        
        filelHandler.readabilityHandler = { pipe in
            let data = pipe.availableData
            if let line = String(data: data, encoding: .utf8) {
                DispatchQueue.main.sync {
                    //self.output_window.string += line
                }
            } else {
                print("Error decoding data: \(data.base64EncodedString())")
            }
        }
        process.waitUntilExit()
        filelHandler.readabilityHandler = nil
    }
    
    @objc func cancel(_ sender: Any?) {
        self.view.window?.close()
    }
    
}
