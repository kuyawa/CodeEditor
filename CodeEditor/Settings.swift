//
//  Settings.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/23/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Foundation


struct Settings {
    var theme = "light"
    var isDarkTheme: Bool {
        get { return theme == "dark" }
        set {
            theme = newValue ? "dark" : "light"
            UserDefaults.standard.set(theme, forKey: "theme")
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

        theme      = Default.string(options["theme"], "light")
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
    
    /*
    func save() {
        guard let url = Bundle.main.url(forResource: "Settings", withExtension: "yaml") else {
            print("WARN: Settings file not found")
            return
        }

        let text = "" //QuickYaml.toString(self)
        
        if (try? text.write(to: url, atomically: false, encoding: .utf8)) != nil {
            print("ERROR: Settings file could not be saved")
            return
        }
    }
    */
}


// End
