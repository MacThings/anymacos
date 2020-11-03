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
    @IBOutlet weak var pulldown_seedmenu: NSPopUpButton!
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    @IBOutlet weak var download_button: NSButton!
    @IBOutlet weak var abort_button: NSButton!
    @IBOutlet weak var create_button: NSButton!
    @IBOutlet weak var percent_symbol: NSTextField!
    @IBOutlet weak var progress_bar: NSProgressIndicator!
    @IBOutlet weak var paypal_button: NSButton!
    @IBOutlet weak var copyright: NSTextField!
    @IBOutlet weak var mb: NSTextField!
    @IBOutlet weak var mb2: NSTextField!
    
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    let languageinit = UserDefaults.standard.string(forKey: "Language")
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "ANYmacOS v. " + appVersion!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let dateStr = formatter.string(from: NSDate() as Date)
        self.copyright.stringValue = "© " + dateStr + " Sascha Lamprecht"

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
        self.progress_wheel?.startAnimation(self);
        UserDefaults.standard.removeObject(forKey: "Choice")
        UserDefaults.standard.removeObject(forKey: "DLFile")
                let defaultname = NSLocalizedString("Retrieving information ...", comment: "")
				UserDefaults.standard.set(defaultname, forKey: "Statustext")
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_select_seed_all"])
            
            DispatchQueue.main.sync {
                let location = NSString(string:"/private/tmp/anymacos/selection").expandingTildeInPath
                self.pulldown_menu.menu?.removeAllItems()
                let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
                self.pulldown_menu.menu?.addItem(withTitle: "", action: #selector(ANYmacOS.menuItemClicked(_:)), keyEquivalent: "")
                for (_, seed) in (fileContent?.components(separatedBy: "\n").enumerated())! {
                    self.pulldown_menu.menu?.addItem(withTitle: seed, action: #selector(ANYmacOS.menuItemClicked(_:)), keyEquivalent: "")
                }
              
            }
            
            DispatchQueue.main.async {
                self.pulldown_menu?.isEnabled=true
                self.download_button?.isEnabled=false
                let defaultname = NSLocalizedString("Idle ...", comment: "")
                UserDefaults.standard.set(defaultname, forKey: "Statustext")
                self.progress_wheel?.stopAnimation(self);
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
        defaults.removeObject(forKey: "OnePhaseInstallPID")
        defaults.removeObject(forKey: "AppValid")
        defaults.removeObject(forKey: "OnePhaseInstall")
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

    @IBAction func tree_select(_ sender: Any) {
        self.download_button.isEnabled=false
        self.pulldown_seedmenu.isEnabled=false
        self.progress_wheel?.startAnimation(self);
        self.pulldown_menu.isEnabled=false
        
        if (sender as AnyObject).title.contains("ll"){
            self.syncShellExec(path: self.scriptPath, args: ["_select_seed_all"])
        }
        if (sender as AnyObject).title.contains("Customer"){
            self.syncShellExec(path: self.scriptPath, args: ["_select_seed_customer"])
        }
        if (sender as AnyObject).title.contains("Developer"){
            self.syncShellExec(path: self.scriptPath, args: ["_select_seed_developer"])
        }
        if (sender as AnyObject).title.contains("Public"){
            self.syncShellExec(path: self.scriptPath, args: ["_select_seed_public"])
        }
        
        let location = NSString(string:"/private/tmp/anymacos/selection").expandingTildeInPath
        self.pulldown_menu.menu?.removeAllItems()
        let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
        self.pulldown_menu.menu?.addItem(withTitle: "", action: #selector(ANYmacOS.menuItemClicked(_:)), keyEquivalent: "")
        for (_, seed) in (fileContent?.components(separatedBy: "\n").enumerated())! {
            self.pulldown_menu.menu?.addItem(withTitle: seed, action: #selector(ANYmacOS.menuItemClicked(_:)), keyEquivalent: "")
        }
        
        self.pulldown_menu.isEnabled=true
        self.pulldown_seedmenu.isEnabled=true
        self.progress_wheel?.stopAnimation(self);
    }
    
    @IBAction func download_os_button(_ sender: Any) {
        self.create_button.isEnabled=false
        self.progress_bar.isHidden=false
        self.percent_symbol.isHidden=false
        self.pulldown_menu.isEnabled=false
        self.pulldown_seedmenu.isEnabled=false
        self.mb.isHidden=false
        self.mb2.isHidden=false
        UserDefaults.standard.removeObject(forKey: "InstallerAppDone")
        UserDefaults.standard.set(false, forKey: "KillDL")
        UserDefaults.standard.set("No", forKey: "Stop")
        self.download_button.isHidden=true
        self.abort_button.isHidden=false

        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_download_macos"])
            
            DispatchQueue.main.async {
                let installerapp_done = UserDefaults.standard.string(forKey: "InstallerAppDone")
                let alert = NSAlert()
                if installerapp_done == "Yes"{
                    alert.messageText = NSLocalizedString("macOS Installer App creation done.", comment: "")
                    alert.informativeText = NSLocalizedString("You can find it Applications Folder. Do you want to clean up the ANYmacOS downloads?", comment: "")
                    alert.alertStyle = .informational
                    alert.icon = NSImage(named: "NSInfo")
                    let Button = NSLocalizedString("Yes", comment: "")
                    alert.addButton(withTitle: Button)
                    let CancelButtonText = NSLocalizedString("No", comment: "")
                    alert.addButton(withTitle: CancelButtonText)
                } else {
                    alert.messageText = NSLocalizedString("An error has occured!", comment: "")
                    alert.informativeText = NSLocalizedString("The creation of the Installer App failed. Please try again. Do you want to clean up the ANYmacOS downloads?", comment: "")
                    alert.alertStyle = .warning
                    alert.icon = NSImage(named: "NSError")
                    let Button = NSLocalizedString("Yes", comment: "")
                    alert.addButton(withTitle: Button)
                    let CancelButtonText = NSLocalizedString("No", comment: "")
                    alert.addButton(withTitle: CancelButtonText)
                }
                
                if alert.runModal() == .alertFirstButtonReturn {
                    self.syncShellExec(path: self.scriptPath, args: ["_remove_downloads"])
                }
                
                self.pulldown_menu.isEnabled=true
                self.pulldown_seedmenu.isEnabled=true
                self.download_button.isHidden=false
                self.abort_button.isHidden=true
                self.percent_symbol.isHidden=true
                self.progress_bar.isHidden=false
                self.create_button.isEnabled=true
                self.mb.isHidden=true
                self.mb2.isHidden=true
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "DLDone")
                defaults.removeObject(forKey: "DLSize")
                defaults.removeObject(forKey: "DLFile")
                defaults.synchronize()
                self.syncShellExec(path: self.scriptPath, args: ["_remove_temp"])
                self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])
                
            }
            
        }
        
    }
    
    @IBAction func stop_download(_ sender: Any) {
        self.percent_symbol.isHidden=true
        self.mb.isHidden=true
        self.mb2.isHidden=true
        self.create_button.isEnabled=false
        UserDefaults.standard.removeObject(forKey: "DLProgress")
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "DLDone")
        defaults.removeObject(forKey: "DLSize")
        defaults.removeObject(forKey: "DLFile")
        defaults.synchronize()
        let defaultname = NSLocalizedString("Canceling Operation ...", comment: "")
		UserDefaults.standard.set(defaultname, forKey: "Statustext")
        
        UserDefaults.standard.set(true, forKey: "KillDL")
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_kill_aria"])
            self.syncShellExec(path: self.scriptPath, args: ["_remove_temp"])
            self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])
            
            DispatchQueue.main.async {
                self.download_button.isHidden=false
                self.abort_button.isHidden=true
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