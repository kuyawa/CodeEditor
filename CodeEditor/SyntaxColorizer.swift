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
    
    var patterns  = Dixy()
    var options   = Dixy()
    var colors    = Dixy()
    var styles    = Dixy()
    var order     = [String]()
    
    var colorText = NSColor("333333")
    var colorBack = NSColor("EEEEEE")
    

    func load(_ syntax: Dixy) {
        // Defaults
        if let app = NSApp.delegate as? AppDelegate, app.settings.isDarkTheme {
            colorText = NSColor("EEEEEE")
            colorBack = NSColor("333333")
        } else {
            colorText = NSColor("333333")
            colorBack = NSColor("EEEEEE")
        }
        
        // User defined
        colors = Dixy() // reset
        if syntax["colors"] != nil {
            for (key, val) in syntax["colors"]! as! Dixy {
                let hex = val as! String
                colors[key] = NSColor(hex)
                if key=="normal" {
                    colorText = colors[key] as! NSColor
                }
                if key=="background" {
                    colorBack = colors[key] as! NSColor
                }
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
        }
        
        if syntax["order"] != nil {
            let items = syntax["order"]! as! String
            order = items.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) }
        }
    }
}

class SyntaxColorizer {
    var textView  : NSTextView?
    var format    : String = "swift"
    var formatter : SyntaxFormatter?
    var isColorizable = false

    struct Attributes {
        let colorNormal: [NSAttributeDescription]   //= [NSForegroundColorAttributeName: formatter?.colorText]
    }
    
    // First assign the textView
    func assignView(_ view: NSTextView) {
        self.textView = view
    }
    
    // Second assign the syntax format and load the formatter from syntax file
    func setFormat(_ format: String) {
        self.format = format
        self.formatter = SyntaxFormatter() // reset
        
        let app = NSApp.delegate as! AppDelegate
        let dark = app.settings.isDarkTheme ? ".dark" : ""

        // Get file for syntax
        guard let url = Bundle.main.url(forResource: "Syntax.\(format)\(dark)", withExtension: "yaml") else {
            print("WARN: Syntax file for \(format) not found")
            isColorizable = false
            return
        }
        
        guard let text = try? String(contentsOf: url) else {
            print("ERROR: Syntax file for \(format) could not be loaded")
            isColorizable = false
            return
        }
        
        let syntax = QuickYaml().parse(text)
        formatter?.load(syntax)
        
        isColorizable = true
    }
    
    // Colorize all
    func colorize() {
        guard isColorizable else { return }
        guard let textView = textView else { return }

        let all = textView.string ?? ""
        let range = NSString(string: textView.string!).range(of: all)
        colorize(range)
    }
    
    // Colorize range
    func colorize(_ range: NSRange) {
        guard isColorizable else { return }
        guard let textView = textView else { return }
        guard let styles = formatter?.styles, styles.count > 0 else { return }
        
        let patterns = formatter?.patterns
        let colors = formatter?.colors
        
        var extended = NSUnionRange(range, NSString(string: textView.string!).lineRange(for: NSMakeRange(range.location, 0)))
            extended = NSUnionRange(range, NSString(string: textView.string!).lineRange(for: NSMakeRange(NSMaxRange(range), 0)))

        // Loop order.array to apply styles in order
        var keys = [String]()
        if let order = formatter?.order, order.count > 0 {
            keys = order
        } else {
            keys = styles.keys.map{ $0 as String }
        }
        
        for style in keys {
            if  let colorName = styles[style],
                let pattern = patterns?[style] as? String,
                let color   = colors?[colorName as! String] as? NSColor
            {
                let attribute = [NSForegroundColorAttributeName: color]
                applyStyles(extended, pattern, attribute)
            }
        }
    }

    func applyStyles(_ range: NSRange, _ pattern: String, _ attribute: [String: Any]) {
        guard let textView = textView else { return }
        let colorNormal = [NSForegroundColorAttributeName: getColorNormal()]
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        regex?.enumerateMatches(in: textView.string!, options: [], range: range) {
            match, flags, stop in

            let matchRange = match?.rangeAt(1)
            textView.textStorage?.addAttributes(attribute, range: matchRange!)
            let maxRange = matchRange!.location + matchRange!.length

            if maxRange + 1 < (textView.textStorage?.length)! {
                textView.textStorage?.addAttributes(colorNormal, range: NSMakeRange(maxRange, 0))
            }
        }
    }
    
    func getColorNormal() -> NSColor {
        if let normal = formatter?.colorText { return normal }
        if let app = NSApp.delegate as? AppDelegate, app.settings.isDarkTheme {
            return NSColor("EEEEEE")
        } else {
            return NSColor("333333")
        }
    }
}


// End
