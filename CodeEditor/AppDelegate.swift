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

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Hello!")
        settings.load()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("Goodbye!")
        return true
    }

}

