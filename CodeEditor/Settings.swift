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
    /// Shared
    static var shared = Settings()
    
    /// Theme
    var theme: String = "system"
    
    /// is Dark mode?
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
    
    /// Font family
    var fontFamily: String = "Menlo"
    
    /// Font size
    var fontSize: CGFloat = 14
    
    /// Word wrap enabled
    var wordWrap: Bool = false
    
    /// Indentation character
    var indentationChar: String = "space"
    
    /// Indentation count
    var indentationCount: Int = 4
    
    /// Default syntax
    var syntaxDefault: String = "swift"
    
    /// Handle unknown files as
    var syntaxUnknown: String = "txt"
    
    /// Syntax list
    var syntaxList: [String: String] = [:]
    
    /// Text color in light mode
    var light_textColor = NSColor("333333")
    
    /// Background color in light mode
    var light_backgroundColor = NSColor("FFFFFF")
    
    /// Text color in dark mode
    var dark_textColor = NSColor("EEEEEE")
    
    /// Background color in dark mode
    var dark_backgroundColor = NSColor("333333")
    
    /// Text color in current mode
    var textColor: NSColor {
        get {
            return isDarkTheme
                ? dark_textColor
                : light_textColor
        }
    }
    
    /// Background color in current mode
    var backgroundColor: NSColor {
        get {
            return isDarkTheme
                ? dark_backgroundColor
                : light_backgroundColor
        }
    }
    
    /**
     * Load the settings.
     *
     * This overwrites the default settings.
     */
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
        
        theme = Default.string(
            options["theme"],
            "system"
        )

        fontFamily = Default.string(
            options["font-family"],
            "menlo"
        )
        
        if let unwrapped = options["font-size"] as? CGFloat {
            fontSize = unwrapped
        }
        
        wordWrap = Default.bool(
            options["word-wrap"],
            false
        )
        
        light_textColor = NSColor(
            Default.string(
                options["light-textColor"],
                "333333"
            )
        )

        light_backgroundColor = NSColor(
            Default.string(
                options["light-backgroundColor"],
                "FFFFFF"
            )
        )
        
        dark_textColor = NSColor(
            Default.string(
                options["dark-textColor"],
                "EEEEEE"
            )
        )
        
        dark_backgroundColor = NSColor(
            Default.string(
                options["dark-backgroundColor"],
                "333333"
            )
        )
        
        indentationChar  = Default.string(
            options["indentation-char"],
            "space"
        )
        
        indentationCount = Default.int(
            options["indentation-count"],
            4
        )
        
        syntaxDefault = Default.string(
            options["syntax-default"],
            "swift"
        )
        
        syntaxUnknown = Default.string(
            options["syntax-unknown"],
            "txt"
        )
        
        if let exts = options["file-extensions"] as? Dixy {
            syntaxList = exts as! [String : String]
        }
        
        // Theme from user defaults if changed
        if let userTheme = UserDefaults.standard.value(forKey: "theme") as? String {
            theme = userTheme
        }
    }
}
// End
