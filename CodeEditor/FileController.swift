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
        case root = "root"
        case folder = "folder"
        case file = "file"
    }

    var root  = FileNode()
    var files = [FileNode]()
    
    var workingFolder = FileNode()
    var currentDocument = FileNode()

    var textView: NSTextView?
    var outlineView: NSOutlineView?
    var onSelected: (_ file: FileNode) -> Void = { file in }
    
    func start() -> FileNode {
        let lastRoot = UserDefaults.standard.url(
            forKey: FileKey.root.rawValue
        )

        let lastFolder = UserDefaults.standard.url(
            forKey: FileKey.folder.rawValue
        )

        let lastFile = UserDefaults.standard.url(
            forKey: FileKey.file.rawValue
        )

        changeRootFolder(lastRoot)
        changeWorkingFolder(lastFolder)
        currentDocument = getFileInfo(lastFile)
        //currentDocument.parent = workingFolder
        
        files = listFolder(root.url)
        print("Root: ", lastRoot ?? "Empty")
        print("Folder: ", lastFolder ?? "Empty")
        print("File: ", lastFile ?? "Empty")
        
        return currentDocument
    }
    
    func assignTree(_ treeView: NSOutlineView) {
        outlineView = treeView
        outlineView?.delegate = self
        outlineView?.dataSource = self
        outlineView?.target = self
    }
    
    func assignEditor(_ editor: NSTextView) {
        textView = editor
    }
    
    func reload() {
        outlineView?.reloadData()
    }
    
    func getWorkingFolder() -> URL? {
        let url = workingFolder.url

        if (url == nil) {
            changeWorkingFolder(
                FileManager.default.homeDirectoryForCurrentUser
            )
            
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
        
        root.children = listFolder(root.url)
    }
    
    func changeWorkingFolder(_ url: URL?) {
        if url == nil {
            workingFolder.url = FileManager.default.homeDirectoryForCurrentUser
        } else {
            workingFolder.url = url
        }
        
        var folder = workingFolder.url!
        if !folder.hasDirectoryPath {
            folder = folder.deletingLastPathComponent()
        }
        
        workingFolder.url  = folder
        workingFolder.name = folder.lastPathComponent
        workingFolder.path = folder.path
        workingFolder.isFolder = folder.hasDirectoryPath
    }
    
    func saveDefaults() {
        print("Saving defaults...")
        UserDefaults.standard.set(
            root.url,
            forKey: FileKey.root.rawValue
        )
        
        UserDefaults.standard.set(
            workingFolder.url,
            forKey: FileKey.folder.rawValue
        )
        
        UserDefaults.standard.set(
            currentDocument.url,
            forKey: FileKey.file.rawValue
        )
    }
    
    func saveRootFolder() {
        UserDefaults.standard.set(
            root.url,
            forKey: FileKey.root.rawValue
        )
    }
    
    func saveWorkingFolder() {
        UserDefaults.standard.set(
            workingFolder.url,
            forKey: FileKey.folder.rawValue
        )
    }
    
    func saveCurrentFile() {
        UserDefaults.standard.set(
            currentDocument.url,
            forKey: FileKey.file.rawValue
        )
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
            let results = fileArray.map {
                url -> FileNode in
                
                do {
                    let info = try url.resourceValues(forKeys: [URLResourceKey.localizedNameKey, URLResourceKey.fileResourceTypeKey, URLResourceKey.creationDateKey, URLResourceKey.fileSizeKey, URLResourceKey.isDirectoryKey])
                    let file = FileNode()
                    file.url = url
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
            
            files = results.sorted(by: { ($0.isFolder ? "0" : "1" + $0.name.lowercased()) < ($1.isFolder ? "0" : "1" + $1.name.lowercased()) }) // sort ascending by name
        }
        
        return files
    }
    
    func walkTheTree(_ file: FileNode) -> FileNode? {
        print("Searching: ", file.url ?? "No file")
        let find = file.url
        if root.url == find { return root }

        // From root to file
        func walker(_ node: FileNode) -> FileNode? {
            print("Walking folder: ", node.url ?? "No folder")
            if let kids = node.children {
                for item in kids {
                    print("Walking item: ", item.url ?? "No item")
                    if item.url == find { return item }
                    if item.isFolder {
                        if let found = walker(item) { return found }
                    }
                }
            }
            
            return nil
        }
        
        let node = walker(file)
        print("Walker found ", node?.url ?? "None")
        
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

    func findNode(_ node: FileNode) -> FileNode? {
        guard let rootUrl = root.url else { return nil }
        guard let fileUrl = node.url else { return nil }
        //print("Finding: ", fileUrl.path)
        
        var row = 0
        var found: FileNode? = nil
        
        // Walk the folders
        func walkTheFolder(_ folder: FileNode) -> FileNode? {
            //print("Walking: ", folder.url?.path)
            
            folder.children = listFolder(folder.url)
            if let children = folder.children {
                for item in children {
                    //print("Checking: ", item.url?.path)
                    if fileUrl == item.url { return item /* Found! */ }
                    row += 1
                    if item.isFolder && item.url != nil && fileUrl.path.hasPrefix(item.url!.deletingLastPathComponent().path) {
                        // Expand folder
                        outlineView?.expandItem(item)
                        found = walkTheFolder(item)
                        if found != nil { break }
                    }
                }
            }
            
            return found
        }

        // Start from the root
        var path = fileUrl.path
        
        if !node.isFolder {
            path = fileUrl.deletingLastPathComponent().path
        }
        
        if path.hasPrefix(rootUrl.path) {
            // if it's contained in root, walk the tree
            for item in files {
                //print("Checking: ", item.url?.path)
                if fileUrl == item.url! { found = item; break }
                row += 1
                if item.isFolder && item.url != nil && fileUrl.path.hasPrefix(item.url!.path) {
                    // Expand folder
                    outlineView?.expandItem(item)
                    found = walkTheFolder(item)
                    if found != nil { break }
                }
            }
            
            if found != nil {
                //print("Found: ", found!.name)
                let index = IndexSet(integer: row)
                outlineView?.selectRowIndexes(index, byExtendingSelection: false)
            } else {
                print("Not found ", fileUrl.path)
            }
        } else { /* change root? */
            var newRoot = fileUrl
            if !fileUrl.hasDirectoryPath {
                newRoot = fileUrl.deletingLastPathComponent()
            }
            changeRootFolder(newRoot)
            saveRootFolder()
            changeWorkingFolder(newRoot)
            saveWorkingFolder()
            files = listFolder(newRoot)
            reload()
            
            // Walk first level only, file is in root
            for item in files {
                if fileUrl == item.url! {
                    found = item
                    break
                }
                row += 1
            }
            
            if found != nil {
                let index = IndexSet(integer: row)
                outlineView?.selectRowIndexes(index, byExtendingSelection: false)
            } else {
                print("Not found ", fileUrl.path)
            }
        }
        
        return found
    }
    
    func findCurrent() {
        _ = findNode(currentDocument)
    }
    
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

        files = listFolder(root.url)
        outlineView?.reloadData()
        findCurrent()

/*
        // Add newfile to treeFolder under current folder
        if root.url == workingFolder.url {
            // TODO: Add to root
            //files.append(currentDocument)
            files = listFolder(root.url)
            outlineView?.reloadData()
            findCurrent()
        } else {
            if let node = findNode(workingFolder) {
                if node.children == nil {
                    node.children = [FileNode]()
                }
                node.children!.append(currentDocument)
                //let index = IndexSet(integer: 0)
                //outlineView?.insertItems(at: index, inParent: node, withAnimation: .slideDown)
                outlineView?.reloadItem(node, reloadChildren: false)
                //outlineView?.expandItem(node)
                findCurrent()
                //outlineView?.selectRowIndexes(index, byExtendingSelection: false)
                // Reload and expand nodes all the way from root to workingFolder
            }
        }
*/
        return .ok
    }

    func open() {
        if currentDocument.hasChanged { _ = save() }

        let dialog = NSOpenPanel()
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = true
        let choice = dialog.runModal()
        
        if choice.rawValue == NSFileHandlingPanelOKButton {
            if let url = dialog.url {
                changeWorkingFolder(url)
                saveWorkingFolder()
                changeRootFolder(workingFolder.url)
                saveRootFolder()
                files = listFolder(root.url)
                reload()
                if !url.hasDirectoryPath {
                    currentDocument = getFileInfo(url)
                    findCurrent()
                    onSelected(currentDocument)
                }
            }
        }
    }
    
    func load(_ filename: String) {
        guard let fileUrl = URL(string: "file://"+filename) else {
            return
        }
        
        let openFile = getFileInfo(fileUrl)
        
        if openFile.url != nil {
            changeRootFolder(fileUrl.deletingLastPathComponent())
            changeWorkingFolder(fileUrl)
            currentDocument = openFile
            reload()
            findCurrent()
            onSelected(openFile)
        }
    }
    
    func save() -> DocumentSaveResult {
        print("Saving \(String(describing: currentDocument.url)) ...")
        
        guard let text = textView?.string else { print("Warn: no text to save"); return .emptyText }
        guard currentDocument.isEditable else { print("Warn: file is not editable"); return .noEditable }
        guard currentDocument.canSave else { print("Warn: file is not editable"); return .noEditable }
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
    
    func delete() {
        guard let url = currentDocument.url else { return }
        print("Deleting file \(String(describing: currentDocument.url))...")
        
        guard var row = outlineView?.row(forItem: currentDocument) else { return }
        let index = IndexSet(integer: row)
        
        do {
            //try FileManager.default.removeItem(at: url)
            try FileManager.default.removeItem(atPath: url.path)
            //files.remove(at: row)
            outlineView?.removeItems(at: index, inParent: nil, withAnimation: NSTableView.AnimationOptions.slideUp)

            // Keep it inside bounds
            let numRows = outlineView?.numberOfRows ?? 0
            if row >= numRows {
                row = numRows - 1
                if row < 0 { row = 0 }
            }
            
            //textView?.string = ""
            outlineView?.selectRowIndexes(index, byExtendingSelection: false)
            //guard let item = outlineView?.item(atRow: row) as? FileNode else { return }

            //if !item.isFolder {
            //    currentDocument = item
            //    onSelected(item)
            //}
            
        } catch {
            Alert("File could not be deleted").show()
            return
        }
        
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
        guard let file = item as? FileNode else { return nil }
        let cellId = "DataCell"
        let result = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? NSTableCellView
        
        result?.textField?.stringValue = file.name
        result?.imageView?.image = file.getFileImage()
        result?.textField?.delegate = self
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
    
    // Edit cell?
    /*
    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
        print("Tree setObjectValue")
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        print("Tree shoudlEdit")
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        print("Tree objectValue")
        return ""
    }
    
    override func didChangeValue(forKey key: String, withSetMutation mutationKind: NSKeyValueSetMutationKind, using objects: Set<AnyHashable>) {
        print("DidChanegValue")
    }
    */
}



extension FileController: NSTextFieldDelegate {
    
    /* Not used but good to know they exist

    override func controlTextDidChange(_ obj: Notification) {
        print("Control didChange")
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        print("Control shouldEndEditing")
        return true
    }
     
    */
    
    func controlTextDidEndEditing(_ obj: Notification) {
        //print("Control endEditing")

        if let field = obj.object as? NSTextField {
            let newName = field.stringValue
            if newName.isEmpty {
                // do not allow empty names, revert to old name
                field.undoManager?.undo()
                return
            } else {
                // Rename file
                if let index = outlineView?.selectedRow {
                    if let item = outlineView?.item(atRow: index) as? FileNode {
                        if item.isFolder {
                            // Don't allow folders to be renamed for now
                            field.undoManager?.undo()
                            return
                        }
                        
                        /*
 
 let result = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? NSTableCellView
 
 result?.textField?.stringValue = file.name
 result?.imageView?.image = file.getFileImage(fileExt: file.ext)
 result?.textField?.delegate = self
 */
                        
                        // If everything ok, rename it
                        do {
                            let source = item.url
                            let target = item.url?.deletingLastPathComponent().appendingPathComponent(newName)
                            print("Rename from source \(source!) to target \(target!)")
                            try FileManager.default.moveItem(at: source!, to: target!)
                            item.url = target
                            item.name = newName
                            
                            // Update image
                            let tableCellView = outlineView?.rowView(atRow: index, makeIfNecessary: false)?.view(atColumn: 0) as? NSTableCellView
                            tableCellView?.imageView?.image = item.getFileImage()
                        } catch {
                            // Revert to old name
                            field.undoManager?.undo()
                        }
                        
                        return
                    }
                }
            }
        }
    }
}


// End
