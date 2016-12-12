//
//  ParserViewController.swift
//  JoseParser
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 25/08/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Cocoa

class ParserViewController: NSViewController {
    @IBOutlet var parserTextView: NSTextView!
    @IBOutlet var parsedTextView: NSTextView!
    @IBOutlet weak var authorTextField: NSTextField!
    @IBOutlet weak var companyTextField: NSTextField!
    @IBOutlet weak var projectNameTextField: NSTextField!
    @IBOutlet weak var parseButton: NSButton!
    @IBOutlet weak var saveFileToDeskopButton: NSButton!
    var parser: Parser!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.registerPreferencesNotification()
        self.setupTextFields()
        self.setupTextViews()
    }
    
    // MARK: - Setup
    
    func registerPreferencesNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayout), name: .preferencesUpdated, object: nil)
    }
    
    func setupTextFields() {
        authorTextField.stringValue = PreferencesKeys.get(setting: PreferencesKeys.author) ?? ""
        companyTextField.stringValue = PreferencesKeys.get(setting: PreferencesKeys.companyName) ?? ""
        projectNameTextField.stringValue = PreferencesKeys.get(setting: PreferencesKeys.projectName) ?? ""
        
        let shouldEnable = PreferencesKeys.get(setting: PreferencesKeys.addCommentsHeader) ?? NSOnState == NSOnState
        authorTextField.isEnabled = shouldEnable
        companyTextField.isEnabled = shouldEnable
        projectNameTextField.isEnabled = shouldEnable
    }
    
    func setupTextViews() {
        self.parserTextView.textStorage?.delegate = self
        self.parsedTextView.textStorage?.delegate = self
    }
    
    // MARK: - Notifications
    
    func updateLayout() {
        setupTextFields()
    }
    
    // MARK: - Actions
    
    @IBAction func parseButtonWasTapped(_ sender: AnyObject) {
        if let text = parserTextView.string {
            parser = Parser(delegate: self)
            parser.parse(textToParse: text)
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
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}

extension ParserViewController: NSTextStorageDelegate {
    override func textStorageDidProcessEditing(_ notification: Notification) {
        if let parserString = parserTextView.string {
            parseButton.isEnabled = !parserString.isEmpty
        } else {
            parseButton.isEnabled = false
        }
        
        if let parsedString = parsedTextView.string {
            saveFileToDeskopButton.isEnabled = !parsedString.isEmpty
        } else {
            saveFileToDeskopButton.isEnabled = false
        }
    }
}

extension ParserViewController: NSControlTextEditingDelegate {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        switch control {
        case authorTextField:
            PreferencesKeys.set(setting: .author, value: fieldEditor.string)
        case projectNameTextField:
            PreferencesKeys.set(setting: .projectName, value: fieldEditor.string)
        case companyTextField:
            PreferencesKeys.set(setting: .companyName, value: fieldEditor.string)
        default:
            break
        }
        
        return true
    }
}

extension ParserViewController: ParserDelegate {
    
    func parseDidSuccess(_ parsedString: String) {
        parsedTextView.string = parsedString
    }
    
    func parseDidFail(_ error: String) {
        // TODO: Show error
        NSBeep()
    }
}
