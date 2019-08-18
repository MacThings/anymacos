//
//  CreateUSBInstaller.swift
//  Treeswitcher
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa

class CreateUSBInstaller: NSViewController {

    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
    
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    @IBOutlet weak var progress_wheel: NSProgressIndicator!
    @IBOutlet weak var start_button: NSButton!
    @IBOutlet weak var select_volume_label: NSTextField!
    @IBOutlet weak var refresh_button: NSButton!
    @IBOutlet weak var one_phase_checkbox: NSButton!
    @IBOutlet weak var one_phase_label: NSTextField!
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    let languageinit = UserDefaults.standard.string(forKey: "Language")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Fix Window Size
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "DRVolName")
        defaults.removeObject(forKey: "DRPartType")
        defaults.removeObject(forKey: "DRFileSys")
        defaults.removeObject(forKey: "DRDevLoc")
        defaults.removeObject(forKey: "DRTotSpace")
        defaults.removeObject(forKey: "DRFreeSpace")
        defaults.removeObject(forKey: "DRMntPoint")
        defaults.synchronize()
        
        self.progress_wheel?.startAnimation(self);
        self.refresh_button.isEnabled=false
        self.start_button.isEnabled=false
        self.select_volume_label.isHidden=true
        self.one_phase_checkbox.isHidden=true
        self.one_phase_label.isHidden=true
        if languageinit == "en" {
            let defaultname = "Looking for suitable Drives ..."
            UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
        } else {
            let defaultname = "Suche nach geeigneten Laufwerken ..."
			UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
        }
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_get_drives"])
            
            DispatchQueue.main.sync {
                let filePath = "/private/tmp/treeswitcher/volumes"
                if (FileManager.default.fileExists(atPath: filePath)) {
                    print("")
                } else{
                    return
                }

                let location = NSString(string:"/private/tmp/treeswitcher/volumes").expandingTildeInPath
                self.pulldown_menu.menu?.removeAllItems()
                let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
                for (_, drive) in (fileContent?.components(separatedBy: "\n").enumerated())! {
                    self.pulldown_menu.menu?.addItem(withTitle: drive, action: #selector(DownloadmacOS.menuItemClicked(_:)), keyEquivalent: "")
                }
            }
            
            DispatchQueue.main.async {
                let filePath = "/private/tmp/treeswitcher/volumes"
                if (FileManager.default.fileExists(atPath: filePath)) {
                    print("")
                } else{
                    if self.languageinit == "en" {
                        let defaultname = "No Drive found ..."
                        UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                    } else {
                        let defaultname = "Kein Laufwerk gefunden ..."
                        UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                    }
                    self.refresh_button.isEnabled=true
                    self.progress_wheel?.stopAnimation(self);
                    self.pulldown_menu.isEnabled=false
                    self.pulldown_menu.menu?.removeAllItems()
                    return
                }
                
                self.refresh_button.isEnabled=true
                self.pulldown_menu?.isEnabled=true
                //self.start_button?.isEnabled=true
                self.select_volume_label.isHidden=false
                self.one_phase_checkbox.isHidden=false
                self.one_phase_label.isHidden=false
                self.progress_wheel?.stopAnimation(self);
                if self.languageinit == "en" {
                    let defaultname = "Idle ..."
                    UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                } else {
                    let defaultname = "Warte ..."
                    UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                }
            }
            

        }
    }
    
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        self.progress_wheel?.startAnimation(self);
        self.start_button.isEnabled=false
        self.refresh_button.isEnabled=false
        self.select_volume_label.isHidden=true
        self.one_phase_checkbox.isHidden=true
        self.one_phase_label.isHidden=true
        if languageinit == "en" {
            let defaultname = "Getting Driveinfos ..."
            UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
        } else {
            let defaultname = "Lese Festplatteninformationen ..."
			UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
        }
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.set(sender.title, forKey: "DriveInfo")
            self.syncShellExec(path: self.scriptPath, args: ["_get_drive_info"])
            
            DispatchQueue.main.async {
                self.progress_wheel?.stopAnimation(self);
                self.select_volume_label.isHidden=false
                self.one_phase_checkbox.isHidden=false
                self.one_phase_label.isHidden=false
                self.start_button?.isEnabled=true
                self.refresh_button.isEnabled=true
                if self.languageinit == "en" {
                    let defaultname = "Idle ..."
                    UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                } else {
                    let defaultname = "Warte ..."
                    UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                }
            }
            
        }
    }
    
    @IBAction func refresh_drives(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "DRVolName")
        defaults.removeObject(forKey: "DRPartType")
        defaults.removeObject(forKey: "DRFileSys")
        defaults.removeObject(forKey: "DRDevLoc")
        defaults.removeObject(forKey: "DRTotSpace")
        defaults.removeObject(forKey: "DRFreeSpace")
        defaults.removeObject(forKey: "DRMntPoint")
        defaults.synchronize()
            self.viewDidLoad()
            self.viewWillAppear()
    }
    
    func syncShellExec(path: String, args: [String] = []) {
        let process            = Process()
        process.launchPath     = "/bin/bash"
        process.arguments      = [path] + args
        let outputPipe         = Pipe()
        process.standardOutput = outputPipe
        process.launch()
        process.waitUntilExit()
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
                   DispatchQueue.main.async {
                        if let timer = self.outputTimer {
                            timer.invalidate()
                            self.outputTimer = nil
                        }
                    }
            }
            process.waitUntilExit()
            DispatchQueue.main.async {
            }
        }
    }
}
