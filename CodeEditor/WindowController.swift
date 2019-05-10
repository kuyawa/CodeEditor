//
//  WindowController.swift
//  Macaw
//
//  Created by Gaëtan Dezeiraud on 10/05/2019.
//  Copyright © 2019 Armonia. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @IBAction func onBuild(_ sender: Any) { build() }
    
    func build() {
        if let viewController = self.contentViewController as? ViewController {
            
            if viewController.filer.root.isFolder {
                //print(viewController.filer.root.path)
                
                // NodeJS - npm
                if FileManager.default.fileExists(atPath: viewController.filer.root.path + "/package.json") {
                    
                    //let res = Utils.shell(launchPath: "/usr/bin/env", arguments: ["npm", "-v" /*"install", "-C", viewController.filer.root.path*/])
                    // Error: env: npm: No such file or directory
                }
                // C & C++ Makefile
                else if FileManager.default.fileExists(atPath: viewController.filer.root.path + "/Makefile") {
                    _ = Utils.shell(launchPath: "/usr/bin/env", arguments: ["make", "-C", viewController.filer.root.path])
                }
            }
        }
    }
}
