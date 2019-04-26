//
//  FileNode.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/22/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa
import Foundation


class FileNode: NSObject {
    var url  : URL?
    var name : String = ""
    var path : String = ""
    var type : URLFileResourceType?
    var date : Date = Date()
    var size : Int  = 0
    
    var isFolder   : Bool = false
    var canSave    : Bool = true
    var parent     : FileNode?
    var children   : [FileNode]?
    var childCount : Int {
        get {
            if children != nil {
                return children!.count
            } else {
                return 0
            }
        }
    }
    
    var ext : String {
        get {
            return url?.pathExtension ?? ""
        }
    }
    
    var isEditable : Bool {
        get {
            //let valid = "swift txt md html xml css js plist py php rb c h json yaml sql"
            let invalid = "exe bin app zip rar tar gz 7z dmg"
            return !invalid.contains(ext)
        }
    }
    
    var hasChanged = false
    
    override var description: String {
        get {
            return "\n Name: \(name)\n Path: \(path)\n Type: \(String(describing: type))\n Date: \(date)\n Size: \(size)\n isFolder: \(isFolder)\n "
        }
    }
    
    func isLeaf() -> Bool {
        return !isFolder
    }
    
    func getFileImage(fileExt: String) -> NSImage {
        if isFolder {
            return NSImage(named: NSImage.folderName)!
        }
        
        return NSWorkspace.shared.icon(forFileType: fileExt)
    }
    
    
}


// End
