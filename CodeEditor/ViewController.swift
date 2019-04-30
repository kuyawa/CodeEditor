//
//  ViewController.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/13/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextViewDelegate, NSTextStorageDelegate {

    let app    = NSApp.delegate as! AppDelegate
    var filer  = FileController()
    var syntax = SyntaxColorizer()
    var isLoading = false
    let hugeFileSize = 9999999  // 10 mbs ?

    
    @IBOutlet weak var mainSplitter : NSSplitView!
    @IBOutlet weak var fileSplitter : NSSplitView!
    
    @IBOutlet weak var mainArea     : NSView!
    @IBOutlet weak var fileArea     : NSView!
    
    @IBOutlet weak var consoleArea  : NSView!
    @IBOutlet weak var editorArea   : NSView!
    @IBOutlet weak var editorTitle  : NSTextField!
    
    @IBOutlet var textEditor        : EditorController!
    @IBOutlet var outlineView       : NSOutlineView!
    
    @IBOutlet weak var buttonNew    : NSButton!
    @IBOutlet weak var buttonOpen   : NSButton!
    @IBOutlet weak var buttonSave   : NSButton!
    @IBOutlet weak var buttonTrash  : NSButton!
    
    
    @IBAction func onOptionsShow(_ sender: AnyObject) { showOptions() }
    @IBAction func onFileNew(_ sender: AnyObject) { fileNew() }
    @IBAction func onFileOpen(_ sender: AnyObject) { fileOpen() }
    @IBAction func onFileOpenInBrowser(_ sender: AnyObject) { fileOpenInBrowser() }
    @IBAction func onFileSave(_ sender: AnyObject) { fileSave() }
    @IBAction func onFileDelete(_ sender: AnyObject) { fileDelete() }
    @IBAction func onSidebarToggle(_ sender: AnyObject) { sidebarToggle(sender) }
    @IBAction func onConsoleToggle(_ sender: AnyObject) { consoleToggle(sender) }
    
    
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
        buttonNew.image   = NSImage(named: goDark ? "icon_new2"   : "icon_new")
        buttonOpen.image  = NSImage(named: goDark ? "icon_open2"  : "icon_open")
        buttonSave.image  = NSImage(named: goDark ? "icon_save2"  : "icon_save")
        buttonTrash.image = NSImage(named: goDark ? "icon_trash2" : "icon_trash")
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

    func initialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(setTheme), name: NSNotification.Name(rawValue: "updateTheme"), object: nil);
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
        textEditor.font = NSFont(name: "Menlo", size: 14) // TODO: Get from defaults
        textEditor.isAutomaticQuoteSubstitutionEnabled  = false
        textEditor.isAutomaticDashSubstitutionEnabled   = false
        textEditor.isAutomaticSpellingCorrectionEnabled = false
        textEditor.isAutomaticLinkDetectionEnabled      = false
        textEditor.textStorage?.font = NSFont(name: "Menlo", size: 14)
        textEditor.textStorage?.delegate = self

        // Horizontal scroll
        textEditor.enclosingScrollView?.hasHorizontalScroller = true
        textEditor.isHorizontallyResizable = true
        textEditor.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        textEditor.textContainer?.containerSize = NSSize(width: Int.max, height: Int.max)
        textEditor.textContainer?.widthTracksTextView = false
        
        // Default colors
        if Settings.shared.isDarkTheme {
            textEditor.backgroundColor = NSColor("333333")
            textEditor.textColor = NSColor("EEEEEE")
        } else {
            textEditor.backgroundColor = NSColor("FFFFFF")
            textEditor.textColor = NSColor("333333")
        }
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
            //textEditor.textStorage?.setAttributes([:], range: all)
            //textEditor.textStorage?.setAttributedString(NSAttributedString(string: ""))
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
    
    func fileOpenInBrowser() {
        if let url = filer.currentDocument.url {
            //print("Open in Browser: ", url)
            NSWorkspace.shared.open(url)
        }
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

