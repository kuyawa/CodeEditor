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
                let filePath = viewController.filer.root.path
                
                // C & C++ Makefile
                if FileManager.default.fileExists(
                    atPath: filePath + "/Makefile"
                    ) {
                    let retVal = Utils.shell(
                        launchPath: "/usr/bin/env",
                        arguments: ["make", "-C", viewController.filer.root.path]
                    )
                    
                    viewController.appendToConsole(retVal)
                }
                // NodeJS - npm
                else if FileManager.default.fileExists(
                    atPath: filePath + "/package.json"
                    ) {
                    let retVal = Utils.shell(
                        launchPath: "/usr/bin/env",
                        arguments: [
                            // Open bash (the trick to remove the "env: node: No such file or directory." error)
                            "/bin/bash",
                            // Force path to npm (hopefully everyone installs it using homebrew.
                            "/usr/local/bin/npm",
                            // @Brouilles original code.
                            "-v",
                            "install",
                            "-C",
                            viewController.filer.root.path
                        ]
                    )
                    
                    /*
                        [17/5/2019 19:35.48] /usr/local/bin/npm: line 2: syntax error near unexpected token `;'
                        /usr/local/bin/npm: line 2: `;(function () { // wrapper in case we're in module_context mode'
                     */
                    
                    viewController.appendToConsole(retVal)
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
