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
    
    @IBOutlet weak var select_os_pd: NSPopUpButton!
    @IBOutlet weak var progress_wheel: NSProgressIndicator!
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    @IBOutlet weak var download_button: NSButton!
    @IBOutlet weak var abort_button: NSButton!
    @IBOutlet weak var close_button: NSButton!
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height);
        self.progress_wheel?.startAnimation(self);
        UserDefaults.standard.set("Retrieving information ...", forKey: "Statustext")
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_select_macos"])
            
            DispatchQueue.main.sync {
                let location = NSString(string:"/private/tmp/treeswitcher/selection").expandingTildeInPath
                self.pulldown_menu.menu?.removeAllItems()
                let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
                
                for (_, seed) in (fileContent?.components(separatedBy: "\n").enumerated())! {
                    self.pulldown_menu.menu?.addItem(withTitle: seed, action: #selector(DownloadmacOS.menuItemClicked(_:)), keyEquivalent: "")
                }
            }
            
            DispatchQueue.main.async {
                self.pulldown_menu?.isEnabled=true
                self.download_button?.isEnabled=true
                UserDefaults.standard.set("", forKey: "Statustext")
                self.progress_wheel?.stopAnimation(self);
            }
        }
    }
    
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "Choice")
    }
 
    @IBAction func select_os_pd(_ sender: Any) {
        let choicefunc = (sender as AnyObject).selectedCell()!.tag
        UserDefaults.standard.set(choicefunc, forKey: "Choice")
    }
    
    @IBAction func download_os_button(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "KillDL")
        self.close_button.isEnabled=false
        self.download_button.isHidden=true
        self.abort_button.isHidden=false
        self.progress_wheel?.startAnimation(self);
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_download_macos"])
            
            DispatchQueue.main.async {
                self.progress_wheel?.stopAnimation(self);
                self.close_button.isEnabled=true
            }
            
        }
    }
    
    @IBAction func stop_download(_ sender: Any) {
        UserDefaults.standard.set("Canceling Operation ...", forKey: "Statustext")
        UserDefaults.standard.set(true, forKey: "KillDL")
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_kill_aria"])
            
            DispatchQueue.main.async {
                self.download_button.isHidden=false
                self.abort_button.isHidden=true
                self.progress_wheel?.stopAnimation(self);
                UserDefaults.standard.set("Operation aborted.", forKey: "Statustext")
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
