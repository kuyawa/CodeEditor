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
    
    var settings = Settings()
    
    override init(){
        super.init()
        print("Hello!")
        settings.load()
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        //Alert("APP File open: \(filename)").show()
        guard let main = NSApp.mainWindow?.contentViewController as! ViewController? else { return true }
        main.fileOpenByOS(filename)
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("Goodbye!")
        return true
    }

}

