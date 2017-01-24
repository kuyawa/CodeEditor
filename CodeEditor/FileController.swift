//
//  Filer.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/19/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa
import Foundation


enum DocumentNewResult {
    case ok, unknownError
}

enum DocumentSaveResult {
    case ok, emptyText, noEditable, invalidName, unknownError
}


class FileController: NSObject {
    enum FileKey: String {
        case root   = "root"
        case folder = "folder"
        case file   = "file"
    }

    var root  = FileNode()
    var files = [FileNode]()
    
    var workingFolder   = FileNode()
    var currentDocument = FileNode()

    var textView    : NSTextView?
    var outlineView : NSOutlineView?
    var onSelected  : (_ file: FileNode) -> Void = { file in }
    
    
    func start() -> FileNode {
        let lastRoot   = UserDefaults.standard.url(forKey: FileKey.root.rawValue)
        let lastFolder = UserDefaults.standard.url(forKey: FileKey.folder.rawValue)
        let lastFile   = UserDefaults.standard.url(forKey: FileKey.file.rawValue)

        changeRootFolder(lastRoot)
        changeWorkingFolder(lastFolder)
        currentDocument = getFileInfo(lastFile)
        //currentDocument.parent = workingFolder
        
        files = listFolder(root.url)
        print("Root: "  , lastRoot   ?? "Empty")
        print("Folder: ", lastFolder ?? "Empty")
        print("File: "  , lastFile   ?? "Empty")
        
        return currentDocument
    }
    
    func assignTree(_ treeView: NSOutlineView) {
        outlineView = treeView
        outlineView?.delegate   = self
        outlineView?.dataSource = self
        outlineView?.target     = self
    }
    
    func assignEditor(_ editor: NSTextView) {
        textView = editor
    }
    
    func reload() {
        outlineView?.reloadData()
        //outlineView?.expandItem(nil, expandChildren: true) // expand all
    }
    
    func getWorkingFolder() -> URL? {
        let url = workingFolder.url

        if url == nil {
            changeWorkingFolder(FileManager.default.homeDirectoryForCurrentUser)
            return workingFolder.url
        }

        if (url?.hasDirectoryPath)! {
            return url
        }
        
        workingFolder.url = url?.deletingLastPathComponent()
        
        return workingFolder.url
    }
    
    func changeRootFolder(_ url: URL?) {
        if let url = url {
            root = getFileInfo(url)
        } else {
            root = getFileInfo(FileManager.default.homeDirectoryForCurrentUser)
        }
        
    }
    
    func changeWorkingFolder(_ url: URL?) {
        if url == nil {
            workingFolder.url = FileManager.default.homeDirectoryForCurrentUser
        } else {
            workingFolder.url = url
        }
        
        var folder = workingFolder.url!
        if !folder.hasDirectoryPath {
            folder = folder.deletingLastPathComponent()  // remove file name if any
        }
        
        workingFolder.name = folder.lastPathComponent
        workingFolder.path = folder.path
        workingFolder.isFolder = folder.hasDirectoryPath
    }
    
    func saveDefaults() {
        print("Saving defaults...")
        UserDefaults.standard.set(root.url, forKey: FileKey.root.rawValue)
        UserDefaults.standard.set(workingFolder.url, forKey: FileKey.folder.rawValue)
        UserDefaults.standard.set(currentDocument.url, forKey: FileKey.file.rawValue)
    }
    
    func saveRootFolder() {
        UserDefaults.standard.set(root.url, forKey: FileKey.root.rawValue)
    }
    
    func saveWorkingFolder() {
        UserDefaults.standard.set(workingFolder.url, forKey: FileKey.folder.rawValue)
    }
    
    func saveCurrentFile() {
        UserDefaults.standard.set(currentDocument.url, forKey: FileKey.file.rawValue)
    }
    
    func getFileInfo(_ url: URL?) -> FileNode {
        let file = FileNode()
        guard url != nil else { return file }
        
        let isDirectory = URLFileResourceType(rawValue: "NSFileTypeDirectory")

        if let info = try? FileManager.default.attributesOfItem(atPath: url!.path) {
            //print("Keys: ", info.keys)
            file.url  = url
            file.name = url!.lastPathComponent
            file.path = url!.path
            file.type = info[FileAttributeKey.type] as! URLFileResourceType?
            file.date = info[FileAttributeKey.creationDate] as! Date
            file.size = info[FileAttributeKey.size] as! Int
            file.isFolder = (file.type! == isDirectory)
        }
        
        return file
    }
    
    func listFolder(_ folder: URL?) -> [FileNode] {
        var files = [FileNode]()
        guard folder != nil else { return files }
        
        let filer  = FileManager.default
        let props  = [URLResourceKey.localizedNameKey, URLResourceKey.fileResourceTypeKey, URLResourceKey.creationDateKey, URLResourceKey.fileSizeKey, URLResourceKey.isDirectoryKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]

        if let fileArray = try? filer.contentsOfDirectory(at: folder!, includingPropertiesForKeys: props, options: options) {
            let results = fileArray.map { url -> FileNode in
                
                do {
                    let info  = try url.resourceValues(forKeys: [URLResourceKey.localizedNameKey, URLResourceKey.fileResourceTypeKey, URLResourceKey.creationDateKey, URLResourceKey.fileSizeKey, URLResourceKey.isDirectoryKey])
                    let file  = FileNode()
                    file.url  = url
                    file.name = info.localizedName ?? "Error"
                    file.path = url.path
                    file.type = info.fileResourceType ?? URLFileResourceType.unknown
                    file.date = info.creationDate ?? Date()
                    file.size = info.fileSize ?? 0
                    file.isFolder = info.isDirectory ?? false
                    if file.isFolder {
                        // Recursive list
                        //file.children = listFolder(file.url)
                    }
                    
                    return file
                    
                } catch {
                    print(error)
                }
                
                let fileError = FileNode()
                
                return fileError
            }
            
            files = results.sorted(by: { $0.name < $1.name }) // sort ascending by name
        }
        
        return files
    }
    
    func walkTheTree(_ file: FileNode) -> FileNode? {
        print("Finding: ", file.url)
        let find = file.url
        if root.url == find { return root }

        // From root to file
        func walker(_ node: FileNode) -> FileNode? {
            print("Walking folder: ", node.url)
            if let kids = node.children {
                for item in kids {
                    print("Walking item: ", item.url)
                    if item.url == find { return item }
                    if item.isFolder {
                        if let found = walker(item) { return found }
                    }
                }
            }
            
            return nil
        }
        
        let node = walker(file)
        print("Walker found ", node?.url)
        
        return node
    }
    
    func fileExists(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        let ok = FileManager.default.fileExists(atPath: url.path)
        return ok
    }
    
}

// Document Extension
extension FileController {

    func new() -> DocumentNewResult {
        if currentDocument.hasChanged { _ = save() }

        let emptyFile = "Empty"
        let url  = getWorkingFolder()
        let doc  = FileNode()
        doc.name = "NewFile.swift" // TODO: default extension from config
        doc.url  = url?.appendingPathComponent(doc.name)
        
        var counter = 0
        while fileExists(doc.url) {
            counter += 1
            doc.name = "NewFile\(counter).swift"
            doc.url  = url?.appendingPathComponent(doc.name)
        }

        currentDocument = doc
        // TODO: catch error
        if doc.url != nil {
            try? emptyFile.write(to: doc.url!, atomically: false, encoding: .utf8)
        }
        print("New file: ", doc.url!)

        // Add newfile to treeFolder under current folder
        if let node = walkTheTree(workingFolder) {
            if node.children == nil {
                node.children = [FileNode]()
            }
            node.children!.append(doc)
            let index = IndexSet(integer: node.childCount)
            outlineView?.insertItems(at: index, inParent: node, withAnimation: .slideDown)
            outlineView?.reloadItem(node, reloadChildren: true)
            outlineView?.expandItem(node)
            // Reload and expand nodes all the way from root to workingFolder
        }
        
        return .ok
    }

    func open() {
        if currentDocument.hasChanged { _ = save() }

        let dialog = NSOpenPanel()
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        let choice = dialog.runModal()
        
        if choice == NSFileHandlingPanelOKButton {
            if let url = dialog.url {
                changeRootFolder(url)
                saveRootFolder()
                changeWorkingFolder(url)
                saveWorkingFolder()
                files = listFolder(url)
                reload()
            }
        }
    }
    
    func load() {
        //
    }

    func save() -> DocumentSaveResult {
        print("Saving \(currentDocument.url) ...")
        
        guard let text = textView?.string else { print("Warn: no text to save"); return .emptyText }
        guard currentDocument.isEditable else { print("Warn: file is not editable"); return .noEditable }
        guard currentDocument.url != nil else { print("Warn: file has invalid name"); return .invalidName }
        
        do {
            try text.write(to: currentDocument.url!, atomically: false, encoding: .utf8)
            print("Saved!")
            return .ok
        } catch {
            print("Error saving file \(currentDocument.url!)")
            print("- \(error)")
        }
        
        return .unknownError
    }

    func saveAs() {
        //
    }

    func duplicate() {
        //
    }

    func rename() {
        //
    }

}


// Outline Extension
extension FileController: NSOutlineViewDataSource, NSOutlineViewDelegate  {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            //print("Child count for root: ", files.count)
            return files.count
        }
        
        if let file = item as? FileNode {
            //print("Child count for ", file.name, file.childCount)
            return file.childCount
        }
        
        //print("Count 0?")
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        var result = FileNode()
        result.name = "Empty"
        //print("Child:", index)
        if item == nil {
            result = self.files[index]
        } else {
            if let file = item as? FileNode, let nodes = file.children {
                if index < file.childCount  {
                    result = nodes[index]
                }
            }
        }
        
        return result
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        //print("Expandable?")
        if let file = item as? FileNode {
            if file.isFolder { return true }
        }
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        if let file = item as? FileNode, let url = file.url {
            if file.isFolder {
                file.children?.removeAll()
                file.children = listFolder(url)
                return true
            }
        }
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        //print("Column item: ", item)
        guard let file = item as? FileNode else { return nil }
        //print("Identifier: ", (tableColumn?.identifier)!)
        
        //let cellId = "filename"
        let cellId = "DataCell"
        let result = outlineView.make(withIdentifier: cellId, owner: self) as? NSTableCellView
        
        result?.textField?.stringValue = file.name
        result?.imageView?.image = file.getFileImage()
        //print("Result: ", result)
        return result
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let view = notification.object as? NSOutlineView {
            let index = view.selectedRow
            if let file = view.item(atRow: index) as? FileNode {
                if currentDocument.hasChanged {
                    if save() != DocumentSaveResult.ok {
                        Alert("Error saving file. Try other means or you will lose your work").show()
                        return
                    }
                }
                
                changeWorkingFolder(file.url)

                if !file.isFolder {
                    currentDocument = file
                    onSelected(file)
                }
            }
        }
    }
    
}


// End
