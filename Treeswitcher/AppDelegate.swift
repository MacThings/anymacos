//
//  AppDelegate.swift
//  Treeswitcher
//
//  Created by Sascha Lamprecht on 13/08/2019.
//  Copyright © 2019 Sascha Lamprecht. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let scriptPath = Bundle.main.path(forResource: "/script/script", ofType: "command")!
    
    func applicationShouldTerminateAfterLastWindowClosed (_
        theApplication: NSApplication) -> Bool {
        return true
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
        
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func reset_settings(_ sender: Any) {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        if let path = Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent().absoluteString {
            NSLog("restart \(path)")
            _ = Process.launchedProcess(launchPath: "/usr/bin/open", arguments: [path])
            NSApp.terminate(self)
            exit(0)
        }
    }

    @IBAction func changelog(_ sender: Any) {
        if let url = URL(string: "https://update.kextupdater.de/treeswitcher/release_menu.html"),
            NSWorkspace.shared.open(url) {
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
    
}
