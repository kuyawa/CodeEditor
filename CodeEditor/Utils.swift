//
//  Utils.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/20/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa
import Foundation


typealias Dixy = [String: Any]

extension String {
    
    func subtext(from pos: Int) -> String {
        guard pos >= 0 else { return "" }
        
        if pos > self.characters.count { return  "" }
        
        let first = self.index(self.startIndex, offsetBy: pos)
        let text  = self.substring(from: first)
        
        return text
    }

    func subtext(to pos: Int) -> String {
        var end = pos
        
        if pos > self.characters.count { end = self.characters.count }
        
        let last = self.index(self.startIndex, offsetBy: end)
        let text = self.substring(to: last)
        
        return text
    }

    func subtext(from ini: Int, to end: Int) -> String {
        guard ini >= 0 else { return "" }
        guard end >= 0 else { return "" }
        
        var fin = end
        
        if ini > self.characters.count { return  "" }
        if end > self.characters.count { fin = self.characters.count }
        
        let first = self.index(self.startIndex, offsetBy: ini)
        let last  = self.index(self.startIndex, offsetBy: fin)
        let range = first ..< last
        let text  = self.substring(with: range)
        
        return text
    }

}


extension NSColor {

    // Use: NSColor("ffffff")
    convenience init(_ hex: String) {
        if let hexInt = Int(hex.lowercased(), radix: 16) {
            self.init(hex: hexInt)
        } else {
            self.init(hex: 0)
        }
    }

    // Use: NSColor(hex: 0xffffffff)
    convenience init(hex: Int) {
        var opacity : CGFloat = 1.0
        if hex > 0xffffff {
            opacity = CGFloat((hex >> 24) & 0xff) / 255
        }
        let parts = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255,
            A: opacity
        )
        //print(parts)
        self.init(red: parts.R, green: parts.G, blue: parts.B, alpha: parts.A)
    }
    
    // Use: NSColor(RGB:(128,255,255))
    convenience init(RGB: (Int, Int, Int)) {
        self.init(
            red  : CGFloat(RGB.0)/255,
            green: CGFloat(RGB.1)/255,
            blue : CGFloat(RGB.2)/255,
            alpha: 1.0
        )
    }

}


class Default {
    static func string(_ val: Any?, _ def: String? = "") -> String {
        return val as! String? ?? def!
    }
    
    static func int(_ val: Any?, _ def: Int? = 0) -> Int {
        let str: String = val as! String? ?? "\(def!)"
        return Int(str) ?? def!
    }
    
    static func double(_ val: Any?, _ def: Double? = 0.0) -> Double {
        let str: String = val as! String? ?? "\(def!)"
        return Double(str) ?? def!
    }
    
    static func bool(_ val: Any?, _ def: Bool? = false) -> Bool {
        let str: String = val as! String? ?? "\(def!)"
        return Bool(str) ?? def!
    }
}



/*
 Use:
 
 Alert("Everything is OK").show()
 Alert(title:"Warning", info:"Something went wrong").show()

 */
class Alert {
    var title :String = "Warning"
    var info  :String = "Something went wrong"
    
    init(_ info: String){
        self.title = "Alert"
        self.info  = info
    }
    
    init(title: String, info: String){
        self.title = title
        self.info  = info
    }
    
    func show() {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}


/*
 Use:
 
 Toast("Everything is OK", self.view.window).show(5)
 
 */

class Toast {
    var info   : String = "Toasted!"
    var window : NSWindow?
    
    init(_ info: String, _ window: NSWindow){
        self.info  = info
        self.window = window
    }
    
    func show(_ secs: Int) {
        guard let window = self.window else { return }
        
        let alert = NSAlert()
        alert.informativeText = info
        //alert.addButton(withTitle: "OK")
        let timer: DispatchTime = .now() + .milliseconds(secs * 1000)
        
        DispatchQueue.main.asyncAfter(deadline: timer) {
            print("Hide!")
            window.endSheet(alert.window)
        }
        
        alert.beginSheetModal(for: window) { NSModalResponse in
            print("Dismissed")
        }
    }
}
    

/*
 Use:
 
 Dialog("Everything is OK?").choice()
 Dialog(title:"Warning", info:"The file will be deleted!").choice()
 
 */
class Dialog {
    var title :String = "Message"
    var info  :String = "Would you like to proceed?"
    
    init(_ info: String){
        self.info  = info
    }
    
    init(title: String, info: String){
        self.title = title
        self.info  = info
    }
    
    func choice() -> Bool{
        var ok = false
        let alert  = NSAlert()
        
        alert.messageText = title
        alert.informativeText = info
        alert.addButton(withTitle: "NO")
        alert.addButton(withTitle: "YES")
        ok = (alert.runModal() == NSAlertSecondButtonReturn)
        
        return ok
    }
}


// End
