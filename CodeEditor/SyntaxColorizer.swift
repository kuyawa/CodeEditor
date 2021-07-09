//
//  SyntaxColorizer.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/18/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa
import Foundation


class SyntaxFormatter {
    
    var colors     = Dixy()
    var styles     = Dixy()
    var stylesDark = Dixy()
    var patterns   = Dixy()
    var options    = Dixy()
    var order      = [String]()
    
    var colorTextLite = NSColor("333333")
    var colorBackLite = NSColor("FFFFFF")
    var colorTextDark = NSColor("EEEEEE")
    var colorBackDark = NSColor("333333")
    

    func load(_ syntax: Dixy) {
        // User defined
        colors = Dixy() // reset
        if syntax["colors"] != nil {
            for (key, val) in syntax["colors"]! as! Dixy {
                let hex = val as! String
                colors[key] = NSColor(hex)
            }
        }

        patterns = Dixy() // reset
        if syntax["patterns"] != nil {
            patterns = syntax["patterns"]! as! Dixy
        }
        
        if syntax["options"] != nil {
            options = syntax["options"]! as! Dixy
        }
        
        if syntax["styles"] != nil {
            styles = syntax["styles"]! as! Dixy
            if let fore = styles["foreground"] {
                colorTextLite = colors[fore as! String] as! NSColor
            }
            if let back = styles["background"] {
                colorBackLite = colors[back as! String] as! NSColor
            }
        }
        
        if syntax["styles-dark"] != nil {
            stylesDark = syntax["styles-dark"]! as! Dixy
            if let fore = stylesDark["foreground"] {
                colorTextDark = colors[fore as! String] as! NSColor
            }
            if let back = stylesDark["background"] {
                colorBackDark = colors[back as! String] as! NSColor
            }
        }
        
        if syntax["order"] != nil {
            let items = syntax["order"]! as! String
            order = items.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) }
        }
    }
}

class SyntaxColorizer {
    var textView  : NSTextView?
    var fileExt   : String = "swift"
    var format    : String = "swift"
    var formatter : SyntaxFormatter?
    var isDark = false
    var isColorizable = false

    // First assign the textView
    func assignView(_ view: NSTextView) {
        self.textView = view
    }
    
    // Second assign the syntax format and load the formatter from syntax file
    func setFormat(_ ext: String) {
        fileExt = ext
        isColorizable = false
        
        let app = NSApp.delegate as! AppDelegate
        isDark  = Settings.shared.isDarkTheme

        // Get syntax file
        var name = ""
        if let syntax = Settings.shared.syntaxList[ext] {
            name   = syntax
            format = syntax
        } else {
            name   = "\(ext).default.yaml"
            format = ext
        }

        self.formatter = SyntaxFormatter() // reset
        
        // First get syntax from app folder, if not found then use from bundle
        let filer = FileManager.default
        var url = app.appFolderUrl?.appendingPathComponent(name)

        if url == nil {
            url = Bundle.main.url(file: name)
        }
        
        if url == nil {
            print("WARN: Syntax file for \(ext) not accessible")
            return
        }
        
        if !filer.fileExists(atPath: url!.path) {
            print("WARN: Syntax file for \(ext) not found at \(url!.path)")
            return
        }
        
        guard let text = try? String(contentsOf: url!) else {
            print("ERROR: Syntax file for \(ext) could not be loaded")
            return
        }
        
        let syntax = QuickYaml().parse(text)
        
        formatter?.load(syntax)
        textView?.backgroundColor = getBackgroundColor()
        isColorizable = true
    }
    
    // Colorize all
    func colorize() {
        guard isColorizable else { return }
        guard let textView = textView else { return }
        let all = textView.string // Non-optional, so no guard

        let range = NSString(string: all).range(of: all)
        colorize(range)
    }
    
    // Colorize range
    func colorize(_ range: NSRange) {
        guard isColorizable else { return }
        guard let textView = textView else { return }
        let text = textView.string // Non-optional, so no guard
        guard let formatter = formatter else { return }
        guard !text.isEmpty else { return }

        var styles = Dixy()

        if isDark {
            styles = formatter.stylesDark
        } else {
            styles = formatter.styles
        }
        
        if styles.count < 1 { return }
        
        let colors   = formatter.colors
        let patterns = formatter.patterns
        let options  = formatter.options
        
        var extended = NSUnionRange(range, NSString(string: text).lineRange(for: NSMakeRange(range.location, 0)))
            extended = NSUnionRange(range, NSString(string: text).lineRange(for: NSMakeRange(NSMaxRange(range), 0)))

        // Loop order.array to apply styles in order
        var keys = [String]()
        let order = formatter.order
        
        if order.count > 0 {
            keys = order
        } else {
            keys = styles.keys.map{ $0 as String }
        }
        
        // Now apply styles
        for style in keys {
            if  let colorName = styles[style],
                let pattern   = patterns[style] as? String,
                let color     = colors[colorName as! String] as? NSColor
            {
                let attribute = [NSAttributedString.Key.foregroundColor: color]
                var option: NSRegularExpression.Options = []
                let styleopt = options[style] as? String
                if let multi = styleopt, multi == "multiline" {
                    //print("Multiline: \(style) \(styleopt)")
                    option = [.dotMatchesLineSeparators]
                }
                applyStyles(extended, pattern, option, attribute)
            }
        }
    }

    func applyStyles(_ range: NSRange, _ pattern: String, _ options: NSRegularExpression.Options, _ attribute: [NSAttributedString.Key: Any]) {
        guard let textView = textView else { return }
        
        let colorNormal = [NSAttributedString.Key.foregroundColor: getColorNormal()]
        let regex = try? NSRegularExpression(pattern: pattern, options: options)
        
        regex?.enumerateMatches(in: textView.string, options: [], range: range) {
            match, flags, stop in

            let matchRange = match?.range(at: 1)
            textView.textStorage?.addAttributes(attribute, range: matchRange!)
            let maxRange = matchRange!.location + matchRange!.length

            if maxRange + 1 < (textView.textStorage?.length)! {
                textView.textStorage?.addAttributes(colorNormal, range: NSMakeRange(maxRange, 0))
            }
        }
    }
    
    func getColorNormal() -> NSColor {
        // If defined use it, else use defaults
        if isDark {
            if let color = formatter?.colorTextDark { return color }
            return NSColor("EEEEEE")
        } else {
            if let color = formatter?.colorTextLite { return color }
            return NSColor("333333")
        }
    }
    
    func getBackgroundColor() -> NSColor {
        // If defined use it, else use defaults
        if isDark {
            if let color = formatter?.colorBackDark { return color }
            return NSColor("333333")
        } else {
            if let color = formatter?.colorBackLite { return color }
            return NSColor("FFFFFF")
        }
    }
}


// End
