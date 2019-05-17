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
                // C & C++ Makefile
                if FileManager.default.fileExists(atPath: viewController.filer.root.path + "/Makefile") {
                    _ = Utils.shell(launchPath: "/usr/bin/env", arguments: ["make", "-C", viewController.filer.root.path])
                }
                else {
                    let alert = NSAlert()
                    alert.messageText = "We can not build."
                    alert.informativeText = "Sorry, but we don't detect a supported build system."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
}
