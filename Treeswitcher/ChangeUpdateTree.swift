//
//  ChangeUpdateTree.swift
//  Treeswitcher
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa

class ChangeUpdateTree: NSViewController {

    @IBOutlet var output_window: NSTextView!
    @IBOutlet weak var content_scroller: NSScrollView!
    @IBOutlet weak var logo: NSImageView!
    @IBOutlet weak var paypal: NSImageView!
    @IBOutlet weak var paypal_button: NSButton!
    @IBOutlet weak var version_label: NSTextField!
    
   
    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
 
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    let appversion : Any! = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        version_label.stringValue = (appversion ?? "") as! String
        
        self.output_window.isHidden=true
        self.content_scroller.isHidden=true
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_initial"])
            self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])
        }
    
        UserDefaults.standard.set(NSUserName(), forKey: "User Name")
        
        let downloadpathinit = UserDefaults.standard.string(forKey: "Downloadpath")
        if downloadpathinit == nil{
            let defaultdir = "/Users/" + NSUserName() + "/Desktop/Treeswitcher/Download"
            UserDefaults.standard.set(defaultdir, forKey: "Downloadpath")
        }
        
        let imagepathinit = UserDefaults.standard.string(forKey: "Imagepath")
        if imagepathinit == nil{
            let defaultdir = "/Users/" + NSUserName() + "/Desktop/Treeswitcher"
            UserDefaults.standard.set(defaultdir, forKey: "Imagepath")
        }
        
        let imagesizeinit = UserDefaults.standard.string(forKey: "Imagesize")
        if imagesizeinit == nil{
            let defaultsize = "8"
            UserDefaults.standard.set(defaultsize, forKey: "Imagesize")
        }
        
        let paradlinit = UserDefaults.standard.string(forKey: "ParaDL")
        if paradlinit == nil{
            let defaultsize = "5"
            UserDefaults.standard.set(defaultsize, forKey: "ParaDL")
        }
        
        let imagenameinit = UserDefaults.standard.string(forKey: "Imagename")
        if imagenameinit == nil{
            let defaultname = "OSInstaller"
            UserDefaults.standard.set(defaultname, forKey: "Imagename")
        }
        
        let volumenameinit = UserDefaults.standard.string(forKey: "Volumename")
        if volumenameinit == nil{
            let defaultname = "Install OS"
            UserDefaults.standard.set(defaultname, forKey: "Volumename")
        }
        let statustextusbinit = UserDefaults.standard.string(forKey: "StatustextUSB")
        if statustextusbinit == nil{
            let defaultname = "Idle"
            UserDefaults.standard.set(defaultname, forKey: "StatustextUSB")
        }
        let onephaseinit = UserDefaults.standard.string(forKey: "OnePhaseInstall")
        if onephaseinit == nil{
            UserDefaults.standard.set(false, forKey: "OnePhaseInstall")
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
        defaults.synchronize()

    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
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
        }
        self.output_window.textStorage?.mutableString.setString("")
        
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_setseed"])
            
            DispatchQueue.main.sync {
                self.logo.isHidden=true
                self.paypal.isHidden=true
                self.paypal_button.isHidden=true
                self.output_window.isHidden=false
                self.content_scroller.isHidden=false
            }
        }
    }

    @IBAction func donate(_ sender: Any) {
        if let url = URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=paypal@sl-soft.de&item_name=Treeswitcher&currency_code=EUR"),
            NSWorkspace.shared.open(url) {
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
                    self.output_window.string += line
                }
            } else {
                print("Error decoding data: \(data.base64EncodedString())")
            }
        }
        process.waitUntilExit()
        filelHandler.readabilityHandler = nil
    }
    
}
