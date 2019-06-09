//
//  ViewController.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/13/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa
import Quartz

class ViewController: NSViewController, NSTextViewDelegate, NSTextStorageDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    /// Appdelegate
    let app = NSApp.delegate as! AppDelegate
    
    /// File Controller
    var filer = FileController()
    
    /// Syntax highlighter
    var syntax = SyntaxColorizer()
    
    /// Is the system loading?
    var isLoading = false
    
    /// Maximum file size.
    let hugeFileSize = 9999999 // 10 mb
    
    /// main screen splitter
    @IBOutlet weak var mainSplitter: NSSplitView!
    
    /// File splitter
    @IBOutlet weak var fileSplitter: NSSplitView!
    
    /// Main View
    @IBOutlet weak var mainArea: NSView!
    
    /// Filetree view
    @IBOutlet weak var fileArea: NSView!
    
    /// Console view
    @IBOutlet weak var consoleArea: NSView!
    
    /// Console text view
    @IBOutlet weak var consoleTextView: NSTextView!
    
    /// Editor view
    @IBOutlet weak var editorArea: NSView!
    
    /// Editor title
    @IBOutlet weak var editorTitle: NSTextField!
    
    /// Text Editor
    @IBOutlet var textEditor: EditorController!
    
    /// Outline view
    @IBOutlet var outlineView: NSOutlineView!
    
    /// New file button
    @IBOutlet weak var buttonNew: NSButton!
    
    /// Open (file) button
    @IBOutlet weak var buttonOpen: NSButton!
    
    /// Save file button
    @IBOutlet weak var buttonSave: NSButton!
    
    /// Trash file button
    @IBOutlet weak var buttonTrash: NSButton!
    
    /// Show options
    @IBAction func onOptionsShow(_ sender: AnyObject) {
        showOptions()
    }
    
    @IBAction func onFileNew(_ sender: AnyObject) {
        fileNew()
    }
    
    @IBAction func onFileOpen(_ sender: AnyObject) {
        fileOpen()
    }
    
    @IBAction func onFileSave(_ sender: AnyObject) {
        fileSave()
    }
    
    @IBAction func onFileDelete(_ sender: AnyObject) {
        fileDelete()
    }
    
    @IBAction func onSidebarToggle(_ sender: AnyObject) {
        sidebarToggle(sender)
    }
    
    @IBAction func onConsoleToggle(_ sender: AnyObject) {
        consoleToggle(sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setTheme()
    }
    
    override func viewWillDisappear() {
        if filer.currentDocument.hasChanged {
            _ = filer.save()
        }
        filer.saveDefaults()
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return 1
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return filer.currentDocument.url! as QLPreviewItem
    }
    
    @objc func setTheme() {
        let goDark = Settings.shared.isDarkTheme
        if #available(OSX 10.14, *) {
            NSApp.appearance = NSAppearance(named: goDark ? .darkAqua : .aqua)
        } else {
            // Fallback on earlier versions
            for window in NSApp.windows {
                window.appearance = NSAppearance(named: goDark ? NSAppearance.Name.vibrantDark : NSAppearance.Name.vibrantLight)
            }
        }
        buttonNew.image = NSImage(named: goDark ? "icon_new2"   : "icon_new")
        buttonOpen.image = NSImage(named: goDark ? "icon_open2"  : "icon_open")
        buttonSave.image = NSImage(named: goDark ? "icon_save2"  : "icon_save")
        buttonTrash.image = NSImage(named: goDark ? "icon_trash2" : "icon_trash")
        
        // Fix textview color.
        textEditor.textColor = Settings.shared.textColor
        textEditor.backgroundColor = Settings.shared.backgroundColor
    }
    
    func sidebarToggle(_ sender: AnyObject) {
        fileArea.isHidden = !fileArea.isHidden
        mainSplitter.adjustSubviews()
        
        // Change mark in menu item
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = NSControl.StateValue(rawValue: fileArea.isHidden ? 0 : 1)
        }
        
        // FIX: Repaint view to remove buggy vertical line
        // WTF?
    }

    func consoleToggle(_ sender: AnyObject) {
        consoleArea.isHidden = !consoleArea.isHidden
        fileSplitter.adjustSubviews()
        
        // Change mark in menu item
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = NSControl.StateValue(rawValue: consoleArea.isHidden ? 0 : 1)
        }
    }

    func appendToConsole(_ text: String) {
        if consoleArea.isHidden {
            self.consoleToggle(self)
        }
        
        // make it not editable.
        consoleTextView.isEditable = false
        
        // get the user's calendar
        let userCalendar = Calendar.current
        
        // choose which date and time components are needed
        let requestedComponents: Set<Calendar.Component> = [
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .second
        ]
        
        // get the components
        let dateTimeComponents = userCalendar.dateComponents(
            requestedComponents,
            from: Date()
        )
    
        if consoleTextView.string == "" {
            consoleTextView.string = "Welcome to Macaw!\n"
        }
        
        consoleTextView.string = "\(consoleTextView.string)[\(dateTimeComponents.day!)/\(dateTimeComponents.month!)/\(dateTimeComponents.year!) \(dateTimeComponents.hour!):\(dateTimeComponents.minute!).\(dateTimeComponents.second!)] \(text)"
        consoleTextView.scrollToEndOfDocument(self)
    }
    
    func initialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(setTheme), name: .updateTheme, object: nil);
        consoleArea.isHidden = true
        
        syntax.assignView(textEditor)
        syntax.setFormat(Settings.shared.syntaxDefault)
        
        let lastFile = filer.start()
        filer.assignTree(outlineView)
        filer.assignEditor(textEditor)
        filer.onSelected = selectedFile
        filer.reload()
        if app.filename.isEmpty {
            filer.findCurrent()
            selectedFile(lastFile)
        } else {
            // will open file passed by OS
        }
    }
    
    func resetEditor() {
        textEditor.font = NSFont(name: Settings.shared.fontFamily, size: Settings.shared.fontSize)
        textEditor.isAutomaticQuoteSubstitutionEnabled  = false
        textEditor.isAutomaticDashSubstitutionEnabled = false
        textEditor.isAutomaticSpellingCorrectionEnabled = false
        textEditor.isAutomaticLinkDetectionEnabled = false
        textEditor.textStorage?.font = NSFont(name: Settings.shared.fontFamily, size: Settings.shared.fontSize)
        textEditor.textStorage?.delegate = self

        // Horizontal scroll
        textEditor.enclosingScrollView?.hasHorizontalScroller = true
        textEditor.isHorizontallyResizable = true
        textEditor.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        textEditor.textContainer?.containerSize = NSSize(width: Int.max, height: Int.max)
        textEditor.textContainer?.widthTracksTextView = false
        
        // Default colors
        textEditor.textColor = Settings.shared.textColor
        textEditor.backgroundColor = Settings.shared.backgroundColor
    }
    
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        //textEditor.process(editedRange)
        //print("Delta \(delta) - Mask: \(editedMask.rawValue)")
        if !isLoading && delta != 0 && editedMask.rawValue > 1 {
            //print("Has changed, colorizing...")
            filer.currentDocument.hasChanged = true
            syntax.colorize(editedRange)
        }
    }

    func setFileName(_ text: String) {
        editorTitle.stringValue = text
    }
    
    func selectedFile(_ file: FileNode) {
        print("Selected: ", file.name)
        if file.isFolder { return }
        if file.name.isEmpty { return }

        setFileName(file.name)
        
        if file.size > hugeFileSize {
            Alert("File size is too big").show()
            file.canSave = false
            textEditor.string = "[\(file.name) is not editable]"
            resetEditor()
            return
        }
        
        if file.url != nil && !file.isFolder && file.isEditable {
            isLoading = true // on load do not colorize in process editing
            
            // Remove old attributes
            let old = NSRange(location: 0, length: textEditor.textStorage?.length ?? 0)
            textEditor.textStorage?.removeAttribute(NSAttributedString.Key.foregroundColor, range: old)
            textEditor.string = ""

            // Assign new text
            do {
                var text = try String(contentsOf: file.url!)
                if text.isEmpty { text = " " }
                textEditor.string = text
                resetEditor()

                // Colorize it!
                syntax.setFormat(file.ext)
                syntax.colorize()
            } catch {
                print("Error loading file ", file.url ?? "No file")
                textEditor.string = "[\(file.name) is not editable]"
                
                // Preview with Quickview
                if let sharedPanel = QLPreviewPanel.shared() {
                    sharedPanel.delegate = self
                    sharedPanel.dataSource = self
                    sharedPanel.makeKeyAndOrderFront(self)
                }
                
                resetEditor()
            }
            
            
            isLoading = false
        }
        
        if !file.isEditable {
            textEditor.string = "[\(file.name) is not editable]"
            file.canSave = false
            resetEditor()
        }
    }

    func showOptions() {
        // TODO:
    }
    
    
    //---- File methods

    func fileNew() {
        let result = filer.new()

        if result == .ok {
            filer.findCurrent()
            selectedFile(filer.currentDocument)
        }
    }
    
    func fileOpen() {
        filer.open()
    }
    
    func fileOpenByOS(_ filename: String) {
        filer.load(filename)
        app.filename = "" // reset
    }
    
    func fileSave() {
        let result = filer.save()
        
        switch result {
        case .emptyText   : Alert("File has no content").show()
        case .noEditable  : Alert("File is not editable").show()
        case .invalidName : Alert("File name is invalid").show()
        case .unknownError: Alert("Unknown error saving file").show()
        default           : savingFile()
        }
    }
    
    func savingFile() {
        buttonSave.title = "Saving"

        let timer1: DispatchTime = .now() + .milliseconds(1000)
        let timer2: DispatchTime = .now() + .milliseconds(4000)
        
        DispatchQueue.main.asyncAfter(deadline: timer1) {
            self.buttonSave.image = NSImage(named: (Settings.shared.isDarkTheme ? "icon_saved2" : "icon_saved"))
            self.buttonSave.title = "Saved"
        }

        DispatchQueue.main.asyncAfter(deadline: timer2) {
            self.buttonSave.image = NSImage(named: (Settings.shared.isDarkTheme ? "icon_save2" : "icon_save"))
            self.buttonSave.title = "Save"
        }
        
    }
    
    func fileDelete() {
        guard let url = filer.currentDocument.url else { return }
        
        let ok = Dialog("File: \(url.lastPathComponent)\nThis file will be deleted. Do you want to proceed?").show()
        
        if ok {
            filer.delete()
        }
    }

}

