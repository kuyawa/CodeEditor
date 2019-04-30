//
//  AppDelegate.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/13/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var appFolderName = "MacawEditor"
    var appFolderUrl: URL?
    var filename: String = ""
    var currentBuild = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)!
    var preferencesController: NSWindowController?
    
    override init(){
        super.init()
        setupAppFolder()
        Settings.shared.load()
    }
    
    func setupAppFolder() {
        var forceInstall = false
        var installError = false
        let filer = FileManager.default
        
        if let libFolder = filer.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
            ).first {
            
            appFolderUrl = libFolder.appendingPathComponent(
                appFolderName, isDirectory: true
            )
            
            if let lastInstall = UserDefaults.standard.object(forKey: "installed") {
                if Int(lastInstall as! Int) < currentBuild {
                    forceInstall = true
                }
            }
            
            if forceInstall || !filer.fileExists(atPath: appFolderUrl!.path) {
                print(forceInstall ? "Upgrading app folder to build \(currentBuild)" : "Setting up app folder")
                do {
                    try filer.createDirectory(at: appFolderUrl!, withIntermediateDirectories: true, attributes: nil)
                    UserDefaults.standard.set(currentBuild, forKey: "installed")
                } catch {
                    installError = true
                    print("Error creating app folder and copying syntax files")
                    Alert("Error creating app folder. Syntax files not loaded. Verify you have permissions to write in folder ~/Library/Application Support/").show()
                }
                
                if !installError {
                    // Copy syntax files to appFolder
                    let files = [
                        "Settings.yaml",
                        "css.default.yaml",
                        "html.default.yaml",
                        "js.default.yaml",
                        "json.default.yaml",
                        "swift.default.yaml",
                        "xml.default.yaml",
                        "php.default.yaml",
                        "yaml.default.yaml"
                    ]
                    
                    print("Copying syntax files to app folder")
                    
                    for item in files {
                        if filer.fileExists(atPath: (appFolderUrl?.appendingPathComponent(item).path)!) {
                            do {
                                try filer.removeItem(at: (appFolderUrl?.appendingPathComponent(item))!)
                            }
                            catch {
                                print("Failed to upgrade \(item)")
                                Alert("Error accessing app folder. Syntax files not loaded. Verify you have permissions to read from folder ~/Library/Application Support/").show()
                            }
                        }
                        
                        if  let source = Bundle.main.url(file: item),
                            let target = appFolderUrl?.appendingPathComponent(item)
                        {
                            do {
                                try filer.copyItem(at: source, to: target)
                            }
                            catch {
                                print("Failed to upgrade \(item)")
                                Alert("Error accessing app folder. Syntax files not loaded. Verify you have permissions to read from folder ~/Library/Application Support/").show()
                            }
                        }
                    }
                }
            }
        } else {
            print("Error accessing app folder")
            Alert("Error accessing app folder. Syntax files not loaded. Verify you have permissions to read from folder ~/Library/Application Support/").show()
        }
    }
    
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        self.filename = filename
        guard let main = NSApp.mainWindow?.contentViewController as! ViewController? else { return true }
        main.fileOpenByOS(filename)
        return true
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        if (preferencesController == nil) {
            let storyboard = NSStoryboard(name: NSStoryboard.Name("Preferences"), bundle: nil)
            preferencesController = storyboard.instantiateInitialController() as? NSWindowController
        }
        
        if (preferencesController != nil) {
            preferencesController!.showWindow(sender)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        //
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        //
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}


// End
