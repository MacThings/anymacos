//
//  ANYmacOS.swift
//  ANYmacOS
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa
import Foundation

class ANYmacOS: NSViewController {
    
    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
    var cmd_result = ""
    var temp_path = "/private/tmp/anymacos"
    let fileManager = FileManager.default

    @IBOutlet weak var progress_wheel: NSProgressIndicator!
    @IBOutlet weak var pulldown_seedmenu: NSPopUpButton!
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    @IBOutlet weak var download_button: NSButton!
    @IBOutlet weak var abort_button: NSButton!
    @IBOutlet weak var create_button: NSButton!
    @IBOutlet weak var paypal_button: NSButton!
    @IBOutlet weak var copyright: NSTextField!
    @IBOutlet weak var show_status: NSButton!
    
    @IBOutlet weak var osversion_label: NSTextField!
    @IBOutlet weak var osbuild_label: NSTextField!
    
    
    @IBOutlet weak var show_set_sys_seed: NSButton!
    
    @IBOutlet weak var sip_alert: NSImageView!
    @IBOutlet weak var sip_alert_label: NSTextField!
    
    
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
        
        let botherseed = UserDefaults.standard.string(forKey: "BotherSeed")
        if botherseed == "NO" {
            show_set_sys_seed.performClick(nil)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        let url = URL(fileURLWithPath: temp_path)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch _ {
            print("")
        }
        
        filesize(file: "/private/tmp/anymacos/test.zip", f: "B")
        
        shell(cmd: #"csrutil status | grep "Kext Signing" | sed "s/.*\://g" | xargs"#)
        let sipcheck1 = cmd_result
        shell(cmd: #"csrutil status | grep "System Integrity Protection status" | sed -e "s/.*\://g" -e "s/\ (.*//g" -e "s/\.//g" | xargs"#)
        let sipcheck2 = cmd_result
        
        if sipcheck1 == "disabled" || sipcheck2 == "disabled" || sipcheck2 == "unknown" {
            UserDefaults.standard.set(false, forKey: "SIP")
        } else {
            UserDefaults.standard.set(true, forKey: "SIP")
        }

        if "\(Locale.preferredLanguages)".contains("de-DE") {
            UserDefaults.standard.set("de", forKey: "Language")
        } else {
            UserDefaults.standard.set("en", forKey: "Language")
        }
        
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        if let index = (systemVersion.range(of: "(")?.upperBound)
        {
            let osvesion = String(systemVersion.prefix(upTo: index))
            osversion_label.stringValue = osvesion.replacingOccurrences(of: "Version ", with: "").replacingOccurrences(of: " (", with: "")
            let osbuild = String(systemVersion.suffix(from: index))
            osbuild_label.stringValue = osbuild.replacingOccurrences(of: "Build ", with: "").replacingOccurrences(of: ")", with: "")
        }
        

        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
        self.progress_wheel?.startAnimation(self);
        UserDefaults.standard.removeObject(forKey: "Choice")
        UserDefaults.standard.removeObject(forKey: "DLFile")
                let defaultname = NSLocalizedString("Retrieving information ...", comment: "")
				UserDefaults.standard.set(defaultname, forKey: "Statustext")
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_select_seed_all"])
            self.syncShellExec(path: self.scriptPath, args: ["_check_arch"])
            
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
        
        let botherseed = UserDefaults.standard.string(forKey: "BotherSeed")
        if botherseed == nil{
            UserDefaults.standard.set("NO", forKey: "BotherSeed")
        }
        
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
        defaults.removeObject(forKey: "AppValid")
        defaults.removeObject(forKey: "DLDone")
        defaults.removeObject(forKey: "DLSize")
        defaults.synchronize()
 
        let locale = Locale.current.languageCode
        
        let downloadpath = UserDefaults.standard.string(forKey: "Downloadpath")
        let sip_status = UserDefaults.standard.bool(forKey: "SIP")
        if sip_status == true {
            self.create_button.isEnabled=false
            let alert = NSAlert()
                alert.messageText = NSLocalizedString("SIP is activated on your system!", comment: "")
            if locale != "de" {
                alert.informativeText = NSLocalizedString("ANYmacOS will only work to a limited extent now. You can only download the individual files for the installer application. You then have to assemble them yourself via the terminal. The same applies to the Installer Creator.\n\nTo copy the commands simply mark it, click right Mousebutton and select 'Copy'.\n\n" + "Catalina and earlier:\nsudo /usr/sbin/installer -pkg " + downloadpath! + "/English.dist -target /\n\n" + "To create an Installer Volume (must be HFS+ formatted):\nsudo \"/Applications/NAME_OF_INSTALLER.app/Contents/Resources/createinstallmedia\" --volume \"TARGET_VOLUME\" --applicationpath \"/Applications/NAME_OF_INSTALLER.app\" --nointeraction", comment: "")
                
            } else {
                alert.informativeText = NSLocalizedString("ANYmacOS kann damit nur noch eingeschränkt arbeiten. Du kannst lediglich die einzelnen Dateien für die Installer Applikationen herunterladen. Du musst sie dann selber im Terminal zusammensetzen. Das selbe gilt für die Erstellung eines Installationdatenträgers.\n\nUm die hier unten stehenden Befehle zu kopieren, einfach markieren, die rechte Maustaste drücken und 'Kopieren' auswählen.\n\n" + "Catalina und davor:\nsudo /usr/sbin/installer -pkg " + downloadpath! + "/English.dist -target /\n\n" + "Erstellung eines Installationdatenträgers (muss HFS+ formatiert sein):\nsudo \"/Applications/NAME_OF_INSTALLER.app/Contents/Resources/createinstallmedia\" --volume \"TARGET_VOLUME\" --applicationpath \"/Applications/NAME_OF_INSTALLER.app\" --nointeraction", comment: "")
                
            }
                alert.alertStyle = .informational
                alert.icon = NSImage(named: "NSError")
                let Button = NSLocalizedString("Ok", comment: "")
                alert.addButton(withTitle: Button)
                alert.runModal()
                return
        }
        
        let sip_alert = UserDefaults.standard.bool(forKey: "SIP")
        if sip_alert == true {
            self.sip_alert.isHidden = false
            self.sip_alert_label.isHidden = false
        }
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
            shell(cmd: "/usr/bin/curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection > " + temp_path + "/selection")
        }
        if (sender as AnyObject).title.contains("Customer"){
            shell(cmd: "/usr/bin/curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection_customerseed > " + temp_path + "/selection")
        }
        if (sender as AnyObject).title.contains("Developer"){
            shell(cmd: "/usr/bin/curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection_beta > " + temp_path + "/selection")
        }
        if (sender as AnyObject).title.contains("Public"){
            shell(cmd: "/usr/bin/curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection_seed > " + temp_path + "/selection")
        }
        
        let location = NSString(string:temp_path + "/selection").expandingTildeInPath
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
      
        self.show_status.performClick(nil)
        
        let hidden_item = UserDefaults.standard.string(forKey: "Downloadpath")!
        
        let url = URL(fileURLWithPath: hidden_item)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch _ {
            print("")
        }
        
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
                let filename = path
                let contents = try! String(contentsOfFile: filename)
                let files = contents.split(separator:"\n")
                for line in files {
                    try! fileManager.removeItem(atPath: hidden_item+"/"+line)
                }
                try! fileManager.removeItem(atPath: hidden_item+"/.anymacos_download")
            }
            
        }

        
        self.create_button.isEnabled=false
        self.pulldown_menu.isEnabled=false
        self.pulldown_seedmenu.isEnabled=false
        UserDefaults.standard.removeObject(forKey: "InstallerAppDone")
        UserDefaults.standard.set(false, forKey: "KillDL")
        UserDefaults.standard.set("No", forKey: "Stop")
        self.download_button.isEnabled=false

        return
        
        DispatchQueue.global(qos: .background).async {

            do {
                try self.fileManager.removeItem(atPath: self.temp_path+"/files")
            } catch _ {
                print("")
            }
            let choice = UserDefaults.standard.string(forKey: "Choice")!
            
            self.shell(cmd: "/usr/bin/curl https://www.sl-soft.de/extern/software/anymacos/seeds/\"" + choice + "\" > \"" + self.temp_path + "\"/files")
    
            
            
            
            //self.syncShellExec(path: self.scriptPath, args: ["_download_macos"])
            
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
                self.download_button.isEnabled=true
                self.create_button.isEnabled=true
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "DLDone")
                defaults.removeObject(forKey: "DLSize")
                defaults.removeObject(forKey: "DLFile")
                defaults.synchronize()
                self.syncShellExec(path: self.scriptPath, args: ["_remove_temp"])
                //self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])
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
            //self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])
            
            DispatchQueue.main.async {
                self.download_button.isHidden=false
                self.progress_wheel?.stopAnimation(self);
                let defaultname = NSLocalizedString("Operation aborted.", comment: "")
                UserDefaults.standard.set(defaultname, forKey: "Statustext")
            }
        }
    }
    
    @objc private func ShowSetSysSeed(notification: NSNotification){
        show_set_sys_seed.performClick(nil)
    }
    
    func filesize(file: String, f: String) {
        let MyUrl = NSURL(fileURLWithPath: file)
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: MyUrl.path!)
        let fileSizeNumber = fileAttributes[FileAttributeKey.size] as! NSNumber
        let fileSize = fileSizeNumber.int64Value
        if f == "MB" {
        var sizeMB = Double(fileSize / 1024)
        sizeMB = Double(sizeMB / 1024)
        print(String(sizeMB))
        } else if f == "B" {
            print(String(fileSize))
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
    
    func shell(cmd: String) {
        let process            = Process()
        process.launchPath     = "/bin/bash"
        process.arguments      = ["-c", cmd]
        let outputPipe         = Pipe()
        let filelHandler       = outputPipe.fileHandleForReading
        process.standardOutput = outputPipe
        let group = DispatchGroup()
        group.enter()
        filelHandler.readabilityHandler = { pipe in
            let data = pipe.availableData
            if data.isEmpty { // EOF
                filelHandler.readabilityHandler = nil
                group.leave()
                return
            }
            if let line = String(data: data, encoding: String.Encoding.utf8) {
                DispatchQueue.main.sync {
                    self.cmd_result = line.replacingOccurrences(of: "\n", with: "")
                }
            } else {
                print("Error decoding data: \(data.base64EncodedString())")
            }
        }
        process.launch() // Start process
        process.waitUntilExit() // Wait for process to terminate.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
