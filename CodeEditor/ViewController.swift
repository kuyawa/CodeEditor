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

    let hugeFileSize = 999999
    
    var isLoading = false

    
    @IBOutlet weak var mainSplitter : NSSplitView!
    @IBOutlet weak var fileSplitter : NSSplitView!
    
    @IBOutlet weak var mainArea     : NSView!
    @IBOutlet weak var fileArea     : NSView!
    
    @IBOutlet weak var consoleArea  : NSView!
    @IBOutlet weak var editorArea   : NSView!
    @IBOutlet weak var editorTitle  : NSTextField!
    @IBOutlet weak var buttonSave   : NSButton!
    
    @IBOutlet var textEditor        : EditorController!
    @IBOutlet var outlineView       : NSOutlineView!
    
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }

    override func viewWillDisappear() {
        //print("Window: ", self.view.window?.frame)
        if filer.currentDocument.hasChanged {
            _ = filer.save()
        }
        filer.saveDefaults()
    }
    
    func initialize() {
        // NSApp.loadSettings()
        consoleArea.isHidden = true
        
        syntax.assignView(textEditor)
        syntax.setFormat(app.settings.syntaxDefault)
        
        let lastFile = filer.start()
        filer.assignTree(outlineView)
        filer.assignEditor(textEditor)
        filer.onSelected = selectedFile
        filer.reload()
        selectedFile(lastFile)
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
        textEditor.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        textEditor.textContainer?.containerSize = NSSize(width: Int.max, height: Int.max)
        textEditor.textContainer?.widthTracksTextView = false
    }
    
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        //textEditor.process(editedRange)
        //print("Delta \(delta) - Mask: \(editedMask.rawValue)")
        if !isLoading && delta != 0 && editedMask.rawValue > 1 {
            print("Has changed, colorizing...")
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
        
        if file.url != nil && !file.isFolder && file.isEditable && file.size < hugeFileSize {
            isLoading = true // on load do not colorize in process editing
            
            // Remove old attributes
            let old = NSRange(location: 0, length: textEditor.textStorage?.length ?? 0)
            textEditor.textStorage?.removeAttribute(NSForegroundColorAttributeName, range: old)
            //textEditor.textStorage?.setAttributes([:], range: all)
            //textEditor.textStorage?.setAttributedString(NSAttributedString(string: ""))
            textEditor.string = ""

            // Assign new text
            let text = try? String(contentsOf: file.url!)
            textEditor.string = text ?? "Error loading file"
            resetEditor()
            
            // Colorize it!
            syntax.setFormat(file.ext)
            syntax.colorize()
            
            isLoading = false
        }
        
        if !file.isEditable {
            textEditor.string = "[\(file.name) is not editable]"
            resetEditor()
        }
    }

    func showOptions() {
        // TODO:
    }

    func fileNew() {
        let result = filer.new()

        if result == .ok {
            selectedFile(filer.currentDocument)
            //setFileName(filer.currentDocument.name)
            //textEditor.string = ""
            //resetEditor()
        }
    }
    
    func fileOpen() {
        filer.open()
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
        buttonSave.title = "Saving..."

        let timer1: DispatchTime = .now() + .milliseconds(1000)
        let timer2: DispatchTime = .now() + .milliseconds(4000)
        
        DispatchQueue.main.asyncAfter(deadline: timer1) {
            self.buttonSave.image = NSImage(named: "icon_saved")
            self.buttonSave.title = "Saved"
        }

        DispatchQueue.main.asyncAfter(deadline: timer2) {
            self.buttonSave.image = NSImage(named: "icon_save")
            self.buttonSave.title = "Save"
        }
        
    }

}

