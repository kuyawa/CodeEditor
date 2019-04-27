//
//  PreferencesWindowController.swift
//  CodeEditor
//
//  Created by Gaëtan Dezeiraud on 27/04/2019.
//  Copyright © 2019 Armonia. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide the window instead of closing
        self.window?.orderOut(sender)
        return false
    }
}
