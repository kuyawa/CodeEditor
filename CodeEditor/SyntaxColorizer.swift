//
//  SyntaxColorizer.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/18/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa
import Foundation

typealias Dixy = [String: Any]

class SyntaxFormatter {
    
    var patterns = Dixy()
    var options  = Dixy()
    var colors   = Dixy()
    var styles   = Dixy()
    var order    = [String]()
    
    func load(_ syntax: Dixy) {
        colors = Dixy() // reset
        if syntax["colors"] != nil {
            for (key, val) in syntax["colors"]! as! Dixy {
                if let hex = Int(val as! String, radix: 16) {
                    colors[key] = NSColor(hex: hex)
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

    struct Attributes {
        static let colorNormal = [NSForegroundColorAttributeName: NSColor.black]
    }
    
    /*
    struct color {
        static let normal     = [NSForegroundColorAttributeName: NSColor.black]
        static let comment    = [NSForegroundColorAttributeName: NSColor(red: 0.00, green: 0.50, blue: 0.00, alpha: 1.0)]
        static let keyword    = [NSForegroundColorAttributeName: NSColor(red: 0.75, green: 0.20, blue: 0.75, alpha: 1.0)]
        static let identifier = [NSForegroundColorAttributeName: NSColor(red: 0.33, green: 0.20, blue: 0.66, alpha: 1.0)]
        static let symbol     = [NSForegroundColorAttributeName: NSColor(red: 0.75, green: 0.50, blue: 0.00, alpha: 1.0)]
        static let type       = [NSForegroundColorAttributeName: NSColor(red: 0.00, green: 0.66, blue: 0.66, alpha: 1.0)]
        static let literal    = [NSForegroundColorAttributeName: NSColor(red: 0.66, green: 0.00, blue: 0.00, alpha: 1.0)]
        static let number     = [NSForegroundColorAttributeName: NSColor(red: 0.00, green: 0.00, blue: 0.75, alpha: 1.0)]
        static let attribute  = [NSForegroundColorAttributeName: NSColor(red: 1.00, green: 0.33, blue: 0.00, alpha: 1.0)]
    }
    */
    
//    struct regex {
//        static let keywords      = "\\b(class|deinit|enum|extension|func|import|init|let|protocol|static|struct|subscript|typealias|var|throws|rethrows|break|case|continue|default|do|else|fallthrough|if|in|for|return|switch|where|while|repeat|catch|guard|defer|try|throw|as|dynamicType|is|new|super|self|Self|Type|associativity|didSet|get|infix|inout|left|mutating|none|nonmutating|operator|override|postfix|precedence|prefix|right|set|unowned((un)?safe)?|weak|willSet|switch|case|default|where|if|else|continue|break|fallthrough|return|while|repeat|for|in|catch|do|operator|prefix|infix|postfix|open|public|internal|fileprivate|private|convenience|dynamic|final|lazy|(non)?mutating|optional|override|required|static|unowned((un)?safe)?|weak|true|false|nil)\\b"
//        static let types         = "\\b(Int|Float|Double|String|Bool|Character|Void|U?Int(8|16|32|64)?|Array|Dictionary|(Array)(<.*>)|(Dictionary)(<.*>)|(Optional)(<.*>)|(protocol)(<.*>))\\b"
//        static let stringLiteral = "(\".*\")"
//        static let numberLiteral = "\\b([0-9]*(\\.[0-9]*)?)\\b"
//        static let symbols       = "(\\+|-|\\*|/|=|\\{|\\}|\\[|\\]|\\(|\\))"
//        static let identifiers   = "(\\B\\$[0-9]+|\\b[\\w^\\d][\\w\\d]*\\b|\\B`[\\w^\\d][\\w\\d]*`\\B)"
//        static let attributes    = "((@)(\\B\\$[0-9]+|\\b[\\w^\\d][\\w\\d]*\\b|\\B`[\\w^\\d][\\w\\d]*`\\B))(\\()(.*)\\)"
//        static let commentLine   = "(//.*)"
//        static let commentBlock  = "(/\\*.*\\*/)" // Not working, regex must search block not line
//    }
    
    /*
    let patterns = [
        regex.commentLine   : color.comment,
        regex.commentBlock  : color.comment,
        regex.stringLiteral : color.literal,
        regex.numberLiteral : color.number,
        regex.keywords      : color.keyword,
        regex.types         : color.type
        /*regex.attributes    : color.attribute*/
        /*regex.identifiers   : color.identifier*/
    ]
    */

    /*
    init(_ textView: NSTextView) {
        self.textView = textView
    }
    */
    
    // First assign the textView
    func assignView(_ view: NSTextView) {
        self.textView = view
    }
    
    // Second assign the syntax format and load the formatter from syntax file
    func setFormat(_ format: String) {
        self.format = format
        self.formatter = SyntaxFormatter() // reset

        // Get file for syntax
        guard let url = Bundle.main.url(forResource: "Syntax.\(format)", withExtension: "yaml") else {
            print("ERROR: Syntax file for \(format) not found")
            return
        }
        
        guard let text = try? String(contentsOf: url) else {
            print("ERROR: Syntax file for \(format) could not be loaded")
            return
        }
        
        let syntax = QuickYaml().parse(text)
        formatter?.load(syntax)
    }
    
    // Colorize all
    func colorize() {
        guard let textView = textView else { return }

        let all = textView.string ?? ""
        let range = NSString(string: textView.string!).range(of: all)
        colorize(range)
    }
    
    // Colorize range
    func colorize(_ range: NSRange) {
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
            let colorName = styles[style]
            if  let pattern = patterns?[style] as? String,
                let color   = colors?[colorName as! String] as? NSColor
            {
                let attribute = [NSForegroundColorAttributeName: color]
                applyStyles(extended, pattern, attribute)
            }
        }
    }

    func applyStyles(_ range: NSRange, _ pattern: String, _ attribute: [String: Any]) {
        guard let textView = textView else { return }
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        regex?.enumerateMatches(in: textView.string!, options: [], range: range) {
            match, flags, stop in

            let matchRange = match?.rangeAt(1)
            textView.textStorage?.addAttributes(attribute, range: matchRange!)
            let maxRange = matchRange!.location + matchRange!.length

            if maxRange + 1 < (textView.textStorage?.length)! {
                textView.textStorage?.addAttributes(Attributes.colorNormal, range: NSMakeRange(maxRange, 1))
            }
        }
    }
}


// End
