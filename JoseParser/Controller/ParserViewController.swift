//
//  ParserViewController.swift
//  JoseParser
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 25/08/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Cocoa

class ParserViewController: NSViewController, NSTextStorageDelegate, ParserDelegate {
    @IBOutlet var parserTextView: NSTextView!
    @IBOutlet var parsedTextView: NSTextView!
    @IBOutlet weak var authorTextField: NSTextField!
    @IBOutlet weak var companyTextField: NSTextField!
    @IBOutlet weak var projectNameTextField: NSTextField!
    @IBOutlet weak var parseButton: NSButton!
    @IBOutlet weak var saveFileToDeskopButton: NSButton!
    var parser = Parser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTextFields()
        self.setupTextViews()
    }
    
    // MARK: - Setup
    
    func setupTextFields() {
        
        if PreferencesKeys.get(setting: PreferencesKeys.addCommentsHeader) ?? NSOnState == NSOnState {
            authorTextField.stringValue = PreferencesKeys.get(setting: PreferencesKeys.author) ?? ""
            companyTextField.stringValue = PreferencesKeys.get(setting: PreferencesKeys.companyName) ?? ""
            projectNameTextField.stringValue = PreferencesKeys.get(setting: PreferencesKeys.projectName) ?? ""
            
        } else {
            authorTextField.isEnabled = false
            companyTextField.isEnabled = false
            projectNameTextField.isEnabled = false
        }
    }
    
    func setupTextViews() {
        self.parserTextView.textStorage?.delegate = self
        self.parsedTextView.textStorage?.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func parseButtonWasTapped(_ sender: AnyObject) {
        if let text = parserTextView.string {
            parser.parse(text, author: authorTextField.stringValue, company: companyTextField.stringValue, projectName: projectNameTextField.stringValue, delegate: self)
        }
    }
    
    @IBAction func saveFileDesktopButtonWasTapped(_ sender: AnyObject) {
        if let text = parsedTextView.string {
            parser.createFile(text)
        }
    }
    
    @IBAction func helpButtonWasTapped(_ sender: NSButton) {
        let alert = NSAlert()
        alert.addButton(withTitle: "Got it!")
        alert.informativeText = "- Paste the model class from Swagger API docs.\n- Tap on Parse button.\n- Check the parsed text is ok or modify it.\n- Tap on Save File in Desktop."
        alert.messageText = "How to use this app"
        alert.beginSheetModal(for: self.view.window!, completionHandler: { modalResponse in
            print("hello")
        }) 
    }
    
    // MARK: - NSTextStorageDelegate
    
    override func textStorageDidProcessEditing(_ notification: Notification) {
        if let parserString = parserTextView.string {
            parseButton.isEnabled = parserString.characters.count > 0
        } else {
            parseButton.isEnabled = false
        }
        
        if let parsedString = parsedTextView.string {
            saveFileToDeskopButton.isEnabled = parsedString.characters.count > 0
        } else {
            saveFileToDeskopButton.isEnabled = false
        }
    }
    
    // MARK: - ParserDelegate
    
    func parserDidSuccess(_ parsedString: String) {
        parsedTextView.string = parsedString
    }
    
    func parseDidFail(_ error: String) {
        NSBeep()
    }
}
