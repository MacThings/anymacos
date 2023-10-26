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

    let languageinit = UserDefaults.standard.string(forKey: "Language")
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    
    
    
    override func viewDidAppear() {
        self.view.window?.title = NSLocalizedString("Preferences", comment: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);

        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_initial"])
        }
        self.view.window?.title = NSLocalizedString("Preferences", comment: "")
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

    @IBAction func reset_download_path(_ sender: Any) {
        let defaultdir = "/Users/" + NSUserName() + "/Desktop/ANYmacOS/Download"
        UserDefaults.standard.set(defaultdir, forKey: "Downloadpath")
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
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.close()
    }
    
    @objc func cancel(_ sender: Any?) {
        self.view.window?.close()
    }
    
}
