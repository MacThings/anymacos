//
//  ANYmacOS.swift
//  ANYmacOS
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa

class ANYmacOS: NSViewController {
    
    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
    
    @IBOutlet weak var progress_wheel: NSProgressIndicator!
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    @IBOutlet weak var download_button: NSButton!
    @IBOutlet weak var create_button: NSButton!
    @IBOutlet weak var paypal_button: NSButton!
    @IBOutlet weak var copyright: NSTextField!
    @IBOutlet weak var show_status: NSButton!
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    let languageinit = UserDefaults.standard.string(forKey: "Language")
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = NSLocalizedString("Main Window", comment: "")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let dateStr = formatter.string(from: NSDate() as Date)
        self.copyright.stringValue = "© " + dateStr + " Sascha Lamprecht"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
        self.progress_wheel?.startAnimation(self)
        UserDefaults.standard.removeObject(forKey: "Choice")
        UserDefaults.standard.removeObject(forKey: "DLFile")
        let defaultname = NSLocalizedString("Retrieving information ...", comment: "")
        UserDefaults.standard.set(defaultname, forKey: "Statustext")
        
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_initial"])
            self.syncShellExec(path: self.scriptPath, args: ["_get_selection"])
            
            DispatchQueue.main.sync {
                let location = NSString(string: "/private/tmp/anymacos_" + NSUserName() + "/selection").expandingTildeInPath
                self.pulldown_menu.menu?.removeAllItems()
                if let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue) {
                    self.pulldown_menu.menu?.addItem(withTitle: "", action: #selector(ANYmacOS.menuItemClicked(_:)), keyEquivalent: "")
                    let seeds = fileContent.components(separatedBy: "\n")
                    for (index, seed) in seeds.enumerated() {
                        self.pulldown_menu.menu?.addItem(withTitle: seed, action: #selector(ANYmacOS.menuItemClicked(_:)), keyEquivalent: "")
                    }
                    self.pulldown_menu?.isEnabled = true
                    self.download_button?.isEnabled = false
                    let defaultname = NSLocalizedString("Idle ...", comment: "")
                    UserDefaults.standard.set(defaultname, forKey: "Statustext")
                    self.progress_wheel?.stopAnimation(self)
                } else {
                    self.pulldown_menu.menu?.addItem(withTitle: "🚫", action: #selector(ANYmacOS.menuItemClicked(_:)), keyEquivalent: "")
                    self.pulldown_menu.isEnabled = false
                    self.progress_wheel?.stopAnimation(self)
                }
            }
        }
    

        
        UserDefaults.standard.set(NSUserName(), forKey: "User Name")
        
        let languageinit = UserDefaults.standard.string(forKey: "Language")
        
        let downloadpathinit = UserDefaults.standard.string(forKey: "Downloadpath")
        if downloadpathinit == nil{
            let defaultdir = "/Users/" + NSUserName() + "/Desktop/ANYmacOS/Download"
            UserDefaults.standard.set(defaultdir, forKey: "Downloadpath")
        }
        
        let paradlinit = UserDefaults.standard.string(forKey: "ParaDL")
        if paradlinit == nil{
            let defaultsize = "5"
            UserDefaults.standard.set(defaultsize, forKey: "ParaDL")
        }

        let statustextusbinit = UserDefaults.standard.string(forKey: "StatustextUSB")
        if statustextusbinit == nil{
            if languageinit == "en" {
                let defaultname = "Idle ..."
                UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
            } else {
                let defaultname = "Warte ..."
                UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
            }
        }
        
        let appvalidinit = UserDefaults.standard.string(forKey: "AppValid")
        if appvalidinit == nil{
            UserDefaults.standard.set(false, forKey: "AppValid")
        }
        
        let write_log = UserDefaults.standard.string(forKey: "WriteLog")
        if write_log == nil{
            UserDefaults.standard.set(false, forKey: "WriteLog")
        }
 
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "DRVolName")
        defaults.removeObject(forKey: "DRPartType")
        defaults.removeObject(forKey: "DRFileSys")
        defaults.removeObject(forKey: "DRDevLoc")
        defaults.removeObject(forKey: "DRTotSpace")
        defaults.removeObject(forKey: "DRFreeSpace")
        defaults.removeObject(forKey: "DRMntPoint")
        defaults.removeObject(forKey: "KillDL")
        defaults.removeObject(forKey: "Applicationpath")
        defaults.removeObject(forKey: "AppValid")
        defaults.removeObject(forKey: "DLDone")
        defaults.removeObject(forKey: "DLSize")
        defaults.synchronize()
    }
   
    @IBAction func donate(_ sender: Any) {
        if let url = URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=paypal@sl-soft.de&item_name=ANYmacOS&currency_code=EUR"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "Choice")
        if (sender as NSMenuItem).title != "" {
            self.download_button?.isEnabled=true
        } else if (sender as NSMenuItem).title == "" {
            self.download_button?.isEnabled=false
        }
    }

    
    @IBAction func download_os_button(_ sender: Any) {
      
        self.show_status.performClick(nil)
        
        let hidden_item = UserDefaults.standard.string(forKey: "Downloadpath")!
        
        let path = hidden_item + "/.anymacos_download"
        let hasFile = FileManager().fileExists(atPath: path)
        if hasFile {
            let alert = NSAlert()
                alert.messageText = NSLocalizedString("Found already downloaded files!", comment: "")
                alert.informativeText = NSLocalizedString("Do you want to resume an old download or do you want download from scratch?", comment: "")
                alert.alertStyle = .informational
                alert.icon = NSImage(named: "NSInfo")
                let Button = NSLocalizedString("From scratch", comment: "")
                alert.addButton(withTitle: Button)
                let CancelButtonText = NSLocalizedString("Resume", comment: "")
                alert.addButton(withTitle: CancelButtonText)
            
            if alert.runModal() == .alertFirstButtonReturn {
                self.syncShellExec(path: self.scriptPath, args: ["_remove_downloads"])
            }
            
        }

        self.create_button.isEnabled=false
        self.pulldown_menu.isEnabled=false
        UserDefaults.standard.removeObject(forKey: "InstallerAppDone")
        UserDefaults.standard.set(false, forKey: "KillDL")
        UserDefaults.standard.set("No", forKey: "Stop")
        self.download_button.isEnabled=false

        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_download_macos"])
            
            DispatchQueue.main.async {
                let installerapp_done = UserDefaults.standard.string(forKey: "InstallerAppDone")
                let alert = NSAlert()
                if installerapp_done == "Yes"{
                    alert.messageText = NSLocalizedString("macOS Installer App creation done.", comment: "")
                    alert.informativeText = NSLocalizedString("You can find it in ANYmacOS Sparseimage. Do you want to clean up the ANYmacOS downloads?", comment: "")
                    alert.alertStyle = .informational
                    alert.icon = NSImage(named: "NSInfo")
                    let Button = NSLocalizedString("Yes", comment: "")
                    alert.addButton(withTitle: Button)
                    let CancelButtonText = NSLocalizedString("No", comment: "")
                    alert.addButton(withTitle: CancelButtonText)
                } else {
                    alert.messageText = NSLocalizedString("Creation of the Installer-App failed!", comment: "")
                    alert.informativeText = NSLocalizedString("The creation of the Installer-App failed. It's 99,9% a SIP problem. But you can start the main-PKG by hand (if you don't aborted the download by hand before) and than the creation of the Install-App in the Application folder should be done.", comment: "")
                    alert.alertStyle = .warning
                    alert.icon = NSImage(named: "NSError")
                    //let Button = NSLocalizedString("Yes", comment: "")
                    //alert.addButton(withTitle: Button)
                    let CancelButtonText = NSLocalizedString("OK", comment: "")
                    alert.addButton(withTitle: CancelButtonText)
                }
                
                if alert.runModal() == .alertFirstButtonReturn {
                    let url = URL(fileURLWithPath: UserDefaults.standard.string(forKey: "Downloadpath") ?? "")
                    if FileManager.default.fileExists(atPath: UserDefaults.standard.string(forKey: "Downloadpath") ?? "") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } else {
                        print("Dateipfad existiert nicht: \(url)")
                    }
                }
                                
                self.pulldown_menu.isEnabled=true
                self.download_button.isEnabled=true
                self.create_button.isEnabled=true
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "DLDone")
                defaults.removeObject(forKey: "DLSize")
                defaults.removeObject(forKey: "DLFile")
                defaults.synchronize()
                self.syncShellExec(path: self.scriptPath, args: ["_remove_temp"])
                if self.languageinit == "en" {
                    let defaultname = "Idle ..."
                    UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                } else {
                    let defaultname = "Warte ..."
                    UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CloseWindow"), object: nil, userInfo: ["name" : Status.close_window as Any])
                
            }
            
        }
    }
    
    @IBAction func stop_download(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "KillDL")
        self.create_button.isEnabled=false
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "DLProgress")
        defaults.removeObject(forKey: "DLDone")
        defaults.removeObject(forKey: "DLSize")
        defaults.removeObject(forKey: "DLFile")
        defaults.synchronize()
        let defaultname = NSLocalizedString("Canceling Operation ...", comment: "")
		UserDefaults.standard.set(defaultname, forKey: "Statustext")
        
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_kill_aria"])
            self.syncShellExec(path: self.scriptPath, args: ["_remove_temp"])
            
            DispatchQueue.main.async {
                self.download_button.isHidden=false
                self.progress_wheel?.stopAnimation(self);
                let defaultname = NSLocalizedString("Operation aborted.", comment: "")
                UserDefaults.standard.set(defaultname, forKey: "Statustext")
            }
        }
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
        process.standardOutput = outputPipe
        process.launch()
        
        DispatchQueue.global().async {
            process.waitUntilExit()
        }
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
