//
//  Settings.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/23/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Foundation
import Cocoa

struct Settings {
    
    // Singleton
    static var shared = Settings()
    
    var theme = "system"
    var isDarkTheme: Bool {
        get {
            if (theme == "system") {
                if #available(OSX 10.14, *) {
                    return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
                }
                else {
                    return false
                }
            }

            return theme == "dark"
        }
    }
    
    var fontFamily = "Menlo"
    var fontSize   = 14
    var wordWrap   = false
    
    var indentationChar  = "space"
    var indentationCount = 4

    var syntaxDefault = "swift"
    var syntaxUnknown = "txt"
    
    var syntaxList: [String: String] = [:]
    
    
    mutating func load() {
        guard let url = Bundle.main.url(forResource: "Settings", withExtension: "yaml") else {
            print("WARN: Settings file not found")
            return
        }
        
        guard let text = try? String(contentsOf: url) else {
            print("ERROR: Settings file could not be loaded")
            return
        }
        
        let options = QuickYaml().parse(text)

        theme      = Default.string(options["theme"], "system")
        fontFamily = Default.string(options["font-family"], "menlo")
        fontSize   = Default.int(options["font-size"], 14)
        wordWrap   = Default.bool(options["word-wrap"], false)
        
        indentationChar  = Default.string(options["indentation-char"], "space")
        indentationCount = Default.int(options["indentation-count"], 4)

        syntaxDefault = Default.string(options["syntax-default"], "swift")
        syntaxUnknown = Default.string(options["syntax-unknown"], "txt")
        
        if let exts = options["extensions"] as? Dixy {
            syntaxList = exts as! [String : String]
        }
        
        // Theme from user defaults if changed
        if let userTheme = UserDefaults.standard.value(forKey: "theme") as? String {
            theme = userTheme
        }
    }
}


// End
