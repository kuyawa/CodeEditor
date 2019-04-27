//
//  PreferencesViewController.swift
//  CodeEditor
//
//  Created by Gaëtan Dezeiraud on 27/04/2019.
//  Copyright © 2019 Dezeiraud. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet weak var menuTheme: NSMenu!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the size for each views
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Update window title with the active TabView Title
        self.parent?.view.window?.title = self.title!
    }
    
    @IBAction func changeTheme(_ sender: NSPopUpButtonCell) {
        Settings.shared.theme = sender.titleOfSelectedItem!.lowercased()
        UserDefaults.standard.set(Settings.shared.theme, forKey: "theme")
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateTheme"), object: nil);
    }
}
