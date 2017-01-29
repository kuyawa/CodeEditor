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
    var settings = Settings()
    
    override init(){
        super.init()
        print("Hello!")
        setupAppFolder()
        settings.load()
    }
    
    func setupAppFolder() {
        
        let filer = FileManager.default
        
        if let libFolder = filer.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            
            appFolderUrl = libFolder.appendingPathComponent(appFolderName, isDirectory: true)
            
            if !filer.fileExists(atPath: appFolderUrl!.path) {
                print("Setting up app folder")
                do {
                    try filer.createDirectory(at: appFolderUrl!, withIntermediateDirectories: true, attributes: nil)

                    // Copy syntax files to appFolder
                    let files = [
                        "Settings.yaml",
                        "css.default.yaml",
                        "html.default.yaml",
                        "js.default.yaml",
                        "json.default.yaml",
                        "swift.default.yaml",
                        "xml.default.yaml",
                        "yaml.default.yaml"
                    ]
                    
                    print("Copying syntax files to app folder")

                    for item in files {
                        if  let source = Bundle.main.url(file: item),
                            let target = appFolderUrl?.appendingPathComponent(item)
                        {
                            //print("Copying file \(source) to \(target)")
                            try filer.copyItem(at: source, to: target)
                        }
                    }
                    
                } catch {
                    print("Error creating app folder and copying syntax files")
                    Alert("Error creating app folder. Syntax files not loaded. Verify you have permissions to write in folder ~/Library/Application Support/").show()
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        //
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        //
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("Goodbye!")
        return true
    }

}


// End
