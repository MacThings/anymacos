//
//  DownloadmacOS.swift
//  Treeswitcher
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa

class DownloadmacOS: NSViewController {
    
    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
    
    @IBOutlet weak var progress_wheel: NSProgressIndicator!
    @IBOutlet weak var pulldown_seedmenu: NSPopUpButton!
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    @IBOutlet weak var download_button: NSButton!
    @IBOutlet weak var abort_button: NSButton!
    @IBOutlet weak var close_button: NSButton!
    @IBOutlet weak var percent_symbol: NSTextField!
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    let languageinit = UserDefaults.standard.string(forKey: "Language")
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
        self.progress_wheel?.startAnimation(self);
        UserDefaults.standard.removeObject(forKey: "Choice")
                let defaultname = NSLocalizedString("Retrieving information ...", comment: "")
				UserDefaults.standard.set(defaultname, forKey: "Statustext")
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_select_seed_all"])
            
            DispatchQueue.main.sync {
                let location = NSString(string:"/private/tmp/treeswitcher/selection").expandingTildeInPath
                self.pulldown_menu.menu?.removeAllItems()
                let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
                self.pulldown_menu.menu?.addItem(withTitle: "", action: #selector(DownloadmacOS.menuItemClicked(_:)), keyEquivalent: "")
                for (_, seed) in (fileContent?.components(separatedBy: "\n").enumerated())! {
                    self.pulldown_menu.menu?.addItem(withTitle: seed, action: #selector(DownloadmacOS.menuItemClicked(_:)), keyEquivalent: "")
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
        
        let location = NSString(string:"/private/tmp/treeswitcher/selection").expandingTildeInPath
        self.pulldown_menu.menu?.removeAllItems()
        let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
        self.pulldown_menu.menu?.addItem(withTitle: "", action: #selector(DownloadmacOS.menuItemClicked(_:)), keyEquivalent: "")
        for (_, seed) in (fileContent?.components(separatedBy: "\n").enumerated())! {
            self.pulldown_menu.menu?.addItem(withTitle: seed, action: #selector(DownloadmacOS.menuItemClicked(_:)), keyEquivalent: "")
        }
        
        self.pulldown_menu.isEnabled=true
        self.pulldown_seedmenu.isEnabled=true
        self.download_button.isEnabled=true
        self.progress_wheel?.stopAnimation(self);
    }
    
    @IBAction func download_os_button(_ sender: Any) {
        self.percent_symbol.isHidden=false
        self.pulldown_menu.isEnabled=false
        UserDefaults.standard.removeObject(forKey: "InstallerAppDone")
        UserDefaults.standard.set(false, forKey: "KillDL")
        UserDefaults.standard.set("No", forKey: "Stop")
        self.close_button.isEnabled=false
        self.download_button.isHidden=true
        self.abort_button.isHidden=false

        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_download_macos"])
            
            DispatchQueue.main.async {
                let installerapp_done = UserDefaults.standard.string(forKey: "InstallerAppDone")
                let alert = NSAlert()
                if installerapp_done == "Yes"{
                    alert.messageText = NSLocalizedString("macOS Installer App creation done.", comment: "")
                    alert.informativeText = NSLocalizedString("You can find it Applications Folder. Do you want to clean up the Treeswitcher downloads?", comment: "")
                    alert.alertStyle = .informational
                    alert.icon = NSImage(named: "NSInfo")
                    let Button = NSLocalizedString("Yes", comment: "")
                    alert.addButton(withTitle: Button)
                    let CancelButtonText = NSLocalizedString("No", comment: "")
                    alert.addButton(withTitle: CancelButtonText)
                } else {
                    alert.messageText = NSLocalizedString("An error has occured!", comment: "")
                    alert.informativeText = NSLocalizedString("The creation of the Installer App failed. Please try again. Do you want to clean up the Treeswitcher downloads?", comment: "")
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
                self.download_button.isHidden=false
                self.abort_button.isHidden=true
                self.close_button.isEnabled=true
                self.percent_symbol.isHidden=true
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "DLDone")
                defaults.removeObject(forKey: "DLSize")
                defaults.synchronize()
                self.syncShellExec(path: self.scriptPath, args: ["_remove_temp"])
                self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])
                
            }
            
        }
        
    }
    
    @IBAction func stop_download(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "DLProgress")
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "DLDone")
        defaults.removeObject(forKey: "DLSize")
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
