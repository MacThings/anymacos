//
//  About.swift
//  ANYmacOS
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa
import AVFoundation


class Status: NSViewController {
    
    var cmd_result = ""
    var temp_path = "/private/tmp/anymacos"
    let fileManager = FileManager.default
    
    @IBOutlet weak var statustext_label: NSTextField!
    
    @IBOutlet weak var dl_filename: NSTextField!
    @IBOutlet weak var dl_filesize: NSTextField!
    @IBOutlet weak var dl_loaded: NSTextField!
    @IBOutlet weak var dl_percent: NSTextField!
    @IBOutlet weak var dl_progressbar: NSProgressIndicator!
    
    @IBOutlet weak var percent_symbol: NSTextField!
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    
    
    override func viewDidAppear() {
        self.view.window?.title = NSLocalizedString("Download", comment: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let url_lp = URL(fileURLWithPath: Bundle.main.resourcePath!)
        var LaunchPath = url_lp.deletingLastPathComponent().deletingLastPathComponent().absoluteString.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: "\\ ")
        LaunchPath.removeLast()
        
        print(LaunchPath)
        filesize(file: "/private/tmp/anymacos/files", f: "B")
        
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

        UserDefaults.standard.removeObject(forKey: "InstallerAppDone")
        UserDefaults.standard.set(false, forKey: "KillDL")
        UserDefaults.standard.set("No", forKey: "Stop")
        
        DispatchQueue.global(qos: .background).async {

            do {
                try self.fileManager.removeItem(atPath: self.temp_path+"/files")
            } catch _ {
                print("")
            }
            let choice = UserDefaults.standard.string(forKey: "Choice")!
            
            self.shell(cmd: "/usr/bin/curl -k https://www.sl-soft.de/extern/software/anymacos/seeds/\"" + choice + "\" > \"" + self.temp_path + "\"/files")

            let dl_path = UserDefaults.standard.string(forKey: "Downloadpath")
            let para_dl = UserDefaults.standard.string(forKey: "ParaDL")
            let filename = self.temp_path+"/files"
            let contents = try! String(contentsOfFile: filename)
            let files = contents.split(separator:"\n")
            for line in files {
                print(line)
                self.shell(cmd: #"/usr/bin/curl -k -s -L -I "# + line + #" | grep "ength:" | sed 's/.*th://g' | xargs | awk '{ byte =$1 /1024/1024; print byte " MB" }' | awk '{printf "%.0f\n", $1}'"#)
                //let filesize = self.cmd_result
                
                self.shell(cmd: LaunchPath + "/Contents/Resources/bin/aria2c --file-allocation=none -c -q -x " + para_dl! + #" -d "# + dl_path! + " " + line )
                print(self.cmd_result)
            }

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

                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "DLDone")
                defaults.removeObject(forKey: "DLSize")
                defaults.removeObject(forKey: "DLFile")
                defaults.synchronize()
                self.syncShellExec(path: self.scriptPath, args: ["_remove_temp"])
                //self.syncShellExec(path: self.scriptPath, args: ["_check_seed"])

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CloseWindow"), object: nil, userInfo: ["name" : Status.close_window as Any])
                
            }
            
        }
        
        
        
        self.percent_symbol.isHidden=false
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.close_window),
            name: NSNotification.Name(rawValue: "CloseWindow"),
            object: nil)
}

    
    @IBAction func stop_download(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "KillDL")
        self.percent_symbol.isHidden=true
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
                let defaultname = NSLocalizedString("Operation aborted.", comment: "")
                UserDefaults.standard.set(defaultname, forKey: "Statustext")
                self.view.window?.close()
            }
        }
    }
    
    @objc func close_window(notification: NSNotification) {
        self.view.window?.close()
    }
    
    func filesize(file: String, f: String) {
        let MyUrl = NSURL(fileURLWithPath: file)
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: MyUrl.path!)
            let fileSizeNumber = fileAttributes[FileAttributeKey.size] as! NSNumber
            let fileSize = fileSizeNumber.int64Value
            if f == "MB" {
            var sizeMB = Double(fileSize / 1024)
            sizeMB = Double(sizeMB / 1024)
            print(String(sizeMB))
            } else if f == "B" {
                print(String(fileSize))
            }
        } catch _ {
            print("")
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
    
}
