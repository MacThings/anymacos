//
//  CreateUSBInstallerTerminal.swift
//  Treeswitcher
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa

class CreateUSBInstallerTerminal: NSViewController {

    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
    
    @IBOutlet weak var volume_name: NSTextField!
    @IBOutlet var output_window: NSTextView!
    @IBOutlet weak var application_path_textfield: NSTextField!
    @IBOutlet weak var abort_button: NSButton!
    @IBOutlet weak var start_button: NSButton!
    @IBOutlet weak var start_button_one_phase: NSButton!
    @IBOutlet weak var progress_wheel: NSProgressIndicator!
    @IBOutlet weak var close_button: NSButton!
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
        let targetvolumename = UserDefaults.standard.string(forKey: "DRVolName")
        volume_name.stringValue = (targetvolumename ?? "")
 
        let applicationpathinit = UserDefaults.standard.string(forKey: "Applicationpath")
        if applicationpathinit != nil{
            self.start_button.isEnabled=false
        }
        
        let onephaseinit = UserDefaults.standard.string(forKey: "OnePhaseInstall")
        if onephaseinit == "0"{
            self.start_button_one_phase.isHidden=true
            self.start_button.isHidden=false
        } else{
            self.start_button_one_phase.isHidden=false
            self.start_button.isHidden=true
        }
    }
    
    @IBAction func start_button(_ sender: Any) {
        output_window.textStorage?.mutableString.setString("")
        self.progress_wheel?.startAnimation(self);
        self.abort_button.isEnabled=true
        self.close_button.isEnabled=false
        self.start_button.isEnabled=false
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_start_installer_creation"])
           
            DispatchQueue.main.async {
                self.abort_button.isEnabled=false
                self.start_button.isEnabled=true
                self.close_button.isEnabled=true
                self.progress_wheel?.stopAnimation(self);
            }
            
        }
    }
    
    @IBAction func start_button_one_phase(_ sender: Any) {
        output_window.textStorage?.mutableString.setString("")
        self.progress_wheel?.startAnimation(self);
        self.abort_button.isEnabled=true
        self.close_button.isEnabled=false
        self.start_button_one_phase.isEnabled=false
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_start_onephase_installer"])
            
            DispatchQueue.main.async {
                self.abort_button.isEnabled=false
                self.start_button_one_phase.isEnabled=true
                self.close_button.isEnabled=true
                self.progress_wheel?.stopAnimation(self);
            }
            
        }
    }
    
    
    @IBAction func abort_button(_ sender: Any) {
        self.asyncShellExec(path: self.scriptPath, args: ["_abort_installer_creation"])
    }
    
    @IBAction func set_applicationpath(_ sender: Any) {
        self.output_window.textStorage?.mutableString.setString("")
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose an Application";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["app"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                application_path_textfield.stringValue = path
                let dlpath = (path as String)
                UserDefaults.standard.set(dlpath, forKey: "Applicationpath")
            }
        } else {
            // User clicked on "Cancel"
            return
        }

        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_check_if_valid"])
            
            DispatchQueue.main.async {
                let applicationvalid = UserDefaults.standard.string(forKey: "AppValid")
                if applicationvalid == nil{
                    let applicationpathinit = UserDefaults.standard.string(forKey: "Applicationpath")
                    if applicationpathinit != nil{
                        let onephaseinit = UserDefaults.standard.string(forKey: "OnePhaseInstall")
                        if onephaseinit == "0"{
                            self.start_button_one_phase.isHidden=true
                            self.start_button_one_phase.isEnabled=false
                            self.start_button.isHidden=false
                            self.start_button.isEnabled=true
                        } else{
                            self.start_button_one_phase.isHidden=false
                            self.start_button_one_phase.isEnabled=true
                            self.start_button.isHidden=true
                            self.start_button.isEnabled=false
                        }
                    }
                }
                if applicationvalid != nil {
                    self.start_button_one_phase.isEnabled=false
                    self.start_button.isEnabled=false
                }
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
                    self.output_window.scrollToEndOfDocument(nil)
                    self.output_window.string += line
                }
            } else {
                print("Error decoding data: \(data.base64EncodedString())")
            }
        }
        process.waitUntilExit()
        filelHandler.readabilityHandler = nil
    }
    
    func asyncShellExec(path: String, args: [String] = []) {
        let process            = Process.init()
        process.launchPath     = "/bin/bash"
        process.arguments      = [path] + args
        let outputPipe         = Pipe()
        let filelHandler       = outputPipe.fileHandleForReading
        process.standardOutput = outputPipe
        process.launch()
        
        DispatchQueue.global().async {
            filelHandler.readabilityHandler = { pipe in
                let data = pipe.availableData
                if let line = String(data: data, encoding: String.Encoding.utf8) {
                    DispatchQueue.main.async {
                        self.output_window.string += line
                        self.output_window.scrollToEndOfDocument(nil)
                        if let timer = self.outputTimer {
                            timer.invalidate()
                            self.outputTimer = nil
                        }
                    }
                } else {
                    print("Error decoding data: \(data.base64EncodedString())")
                }
            }
            process.waitUntilExit()
            DispatchQueue.main.async {
            }
        }
    }
}
