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
    var isDarkTheme: Bool { return theme == "dark" }
    
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
        fontFamily = Default.string(options["fontFamily"], "menlo")
        fontSize   = Default.int(options["fontSize"], 14)
        wordWrap   = Default.bool(options["x"], false)
        
        indentationChar  = Default.string(options["indentation-char"], "space")
        indentationCount = Default.int(options["indentation-count"], 4)

        syntaxDefault = Default.string(options["syntax-default"], "swift")
        syntaxUnknown = Default.string(options["syntax-unknown"], "txt")
        
        for (key, val) in options {
            if key.hasPrefix("syntax-") {
                syntaxList[key.subtext(from: 7)] = Default.string(val)
            }
        }
    }
}


// End
