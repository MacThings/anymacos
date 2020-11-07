//
//  About.swift
//  ANYmacOS
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa


class Status: NSViewController {
    
    @IBOutlet weak var percent_symbol: NSTextField!
    
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    
    
    override func viewDidAppear() {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.percent_symbol.isHidden=false
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
    
    @objc func cancel(_ sender: Any?) {
        //self.view.window?.close()
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
    
}
