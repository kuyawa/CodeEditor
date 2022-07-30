//
//  EditorController.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/21/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa
import Foundation


class EditorController: NSTextView, NSTextViewDelegate {
    let spacer = 4  // TODO: get from defaults
    
    /*
     TODO:
        - if } alone in line, unindent before inserting new line
     */
    
    typealias IndentInfo = (count: Int, stop: Bool, last: Character)
    
    func process(_ range: NSRange) {
        let content = (self.string as NSString)
        let cursor = range.location
        let index = NSRange(location: cursor, length: 0)
        
        let lineRange = content.lineRange(for: index)
        let lineText = content.substring(with: lineRange)
        
        //debugPrint("Line: \(lineText)")
        
        // Ending curly bracket? unindent
        if lineText.trimmingCharacters(in: .whitespacesAndNewlines) == "}" {
            //alignBracket(lineRange)
        }
        
    }
    
    // Stolen from SwiftEditor @ SourceKittenDaemon
    override func insertNewline(_ sender: Any?) {
        super.insertNewline(sender)
        
        let range  = self.selectedRange()
        let cursor = range.location
        guard cursor != NSNotFound else { return }
        
        let content = self.string as NSString
        
        guard let indent = getPrevLineIndent(range) else { return }
        let currentLineRange = content.lineRange(for:
            NSRange(location: cursor, length: 0)
        )
        
        /*
         let previousLineRange = content.lineRange(for: NSRange.init(location: currentLineRange.location - 1, length: 0))
         let previousLine = content.substring(with: previousLineRange)
         
         // get the current indent
         let indentInfo = (count: 0, stop: false, last: Character(" "))
         var indent = previousLine.characters.reduce(indentInfo) { (info: IndentInfo, char) -> IndentInfo in
         guard info.stop == false
         else {
         // remember the last non-whitespace char
         if char == " " || char == "\t" || char == "\n" {
         return info
         } else {
         return (count: info.count, stop: info.stop, last: char)
         }
         }
         switch char {
         case " " : return (stop: false, count: info.count + 1,      last: info.last)
         case "\t": return (stop: false, count: info.count + spacer, last: info.last)
         default  : return (stop: true , count: info.count,          last: info.last)
         }
         }
         */
        
        
        // find the last-non-whitespace char
        var spaceCount = indent.count
        
        switch indent.last {
        case "{":
            spaceCount += spacer
        case "}":
            spaceCount -= spacer
            if (spaceCount < 0) {
                spaceCount = 0
            }
        default:
            break
        }
        
        //debugPrint("Last char: ", indent.last, indent.count)
        
        // insert the new indent
        let start  = NSRange(location: currentLineRange.location, length: 0)
        let spaces = String(repeating: " ", count: spaceCount)
        
        self.insertText(spaces, replacementRange: start)
    }
    
    
    @IBAction func moveLineUp(_ sender: NSMenuItem) {
        self.selectLine(sender)
        self.cut(sender)
        self.moveUp(sender)
        self.moveToBeginningOfLine(sender)
        self.paste(sender)
        self.moveUp(sender)
    }
    
    @IBAction func moveLineDown(_ sender: NSMenuItem) {
        self.selectLine(sender)
        self.cut(sender)
        self.moveDown(sender)
        self.moveToBeginningOfLine(sender)
        self.paste(sender)
        self.moveUp(sender)
    }
    
    @IBAction func deleteLine(_ sender: NSMenuItem) {
        self.selectLine(sender)
        self.deleteBackward(sender)
    }
    
    @IBAction func eraseToEndOfLine(_ sender: NSMenuItem) {
        self.moveToEndOfLineAndModifySelection(sender)
        self.deleteToEndOfLine(sender)
    }
    
    @IBAction func duplicateLine(_ sender: NSMenuItem) {
        debugPrint("DUPLICATE LINE!")
        let content = self.string as NSString
        
        self.selectLine(sender)
        let range = self.selectedRange()
        let text = content.substring(with: range)
        let newLineRange = NSRange(location: range.location + range.length, length: 0)
        //self.smartInsert(for: text, replacing: newLineRange, before: nil, after: nil)
        self.insertText(text, replacementRange: newLineRange)
        self.moveToBeginningOfLine(sender)
        self.moveDown(sender)
    }
    
    @IBAction func indentBlock(_ sender: NSMenuItem) {
        debugPrint("Indent")
    }
    
    @IBAction func unindentBlock(_ sender: NSMenuItem) {
        debugPrint("Unindent")
    }
    
    func alignBracket(_ range: NSRange) {
        debugPrint("Align bracket")
        /*
         guard self.string != nil else { return }
         guard let prevIndent = getPrevLineIndent(range) else { return }
         guard let thisIndent = getThisLineIndent(range) else { return }
         
         var idealIndent = prevIndent.count - spacer
         if idealIndent < 0 { idealIndent = 0 }
         debugPrint("Ideal indent: ", idealIndent)
         
         let currentLineRange = (self.string! as NSString).lineRange(for: NSRange(location: range.location, length: 0))
         
         if thisIndent.count > idealIndent {
         debugPrint("Bracket unindented")
         //self.deleteToBeginOfLine()
         let start = NSRange(location: currentLineRange.location, length: thisIndent.count)
         let spaces = String(repeating: " ", count: idealIndent)
         self.replaceCharacters(in: start, with: spaces)
         //self.insertText(spaces, replacementRange: start)
         } else if thisIndent.count < idealIndent {
         debugPrint("Bracket indented")
         let start  = NSRange(location: currentLineRange.location, length: 0)
         let spaces = String(repeating: " ", count: (idealIndent - thisIndent.count))
         self.insertText(spaces, replacementRange: start)
         } else {
         debugPrint("Bracket in position")
         }
         */
    }
    
    
    // Utils
    
    func getPrevLineIndent(_ range: NSRange) -> IndentInfo? {
        let cursor = range.location
        guard cursor != NSNotFound else { return nil }
        
        let content = self.string as NSString
        
        let currentLineRange  = content.lineRange(
            for: NSRange(location: cursor, length: 0)
        )
        
        let previousLineRange = content.lineRange(
            for: NSRange(location: currentLineRange.location - 1, length: 0)
        )
        
        let previousLineText  = content.substring(with: previousLineRange)
        
        // get the current indent
        let indentInfo = (count: 0, stop: false, last: Character(" "))
        let indent = previousLineText.reduce(indentInfo) {
            (info: IndentInfo, char) -> IndentInfo in
            guard info.stop == false
                else {
                    // remember the last non-whitespace char
                    if char == " " || char == "\t" || char == "\n" {
                        return info
                    } else {
                        return (
                            count: info.count,
                            stop: info.stop,
                            last: char
                        )
                    }
            }
            
            switch char {
            case " " :
                return (
                    stop: false,
                    count: info.count + 1,
                    last: info.last
                )
                
            case "\t":
                return (
                    stop: false,
                    count: info.count + spacer,
                    last: info.last
                )
                
            default:
                return (
                    stop: true,
                    count: info.count,
                    last: info.last
                )
            }
        }
        
        return indent
    }
    
    func getThisLineIndent(_ range: NSRange) -> IndentInfo? {
        let cursor = range.location
        guard cursor != NSNotFound else { return nil }
        
        let content = self.string as NSString
        
        let currentLineRange = content.lineRange(
            for: NSRange(location: cursor, length: 0)
        )
        
        let currentLineText  = content.substring(with: currentLineRange)
        
        // get the current indent
        let indentInfo = (
            count: 0,
            stop: false,
            last: Character(" ")
        )

        let indent = currentLineText.reduce(indentInfo) {
            (info: IndentInfo, char) -> IndentInfo in
            guard info.stop == false
                else {
                    // remember the last non-whitespace char
                    if char == " " || char == "\t" || char == "\n" {
                        return info
                    } else {
                        return (
                            count: info.count,
                            stop: info.stop,
                            last: char
                        )
                    }
            }

            switch char {
            case " " :
                return (
                    stop: false,
                    count: info.count + 1,
                    last: info.last
                )
                
            case "\t":
                return (
                    stop: false,
                    count: info.count + spacer,
                    last: info.last
                )
                
            default:
                return (
                    stop: true,
                    count: info.count,
                    last: info.last
                )
            }
        }
        
        return indent
    }
}
