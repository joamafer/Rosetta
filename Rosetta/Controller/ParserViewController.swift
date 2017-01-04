//
//  ParserViewController.swift
//  Rosetta
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
    
    // TODO: Check if I need this for OSX deployment target specified
    // TODO: Check deployment target
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parser = Parser(delegate: self)
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
        guard let text = parserTextView.string, !text.isEmpty else {
            parseDidFail("The format of the model provided is not correct", hint: "Ensure the format matches the data type from Swagger.")
            
            return
        }
        
        PreferencesKeys.set(setting: .author, value: authorTextField!.stringValue)
        PreferencesKeys.set(setting: .projectName, value: projectNameTextField!.stringValue)
        PreferencesKeys.set(setting: .companyName, value: companyTextField!.stringValue)
        
        let shouldAddCommentsHeader = PreferencesKeys.get(setting: PreferencesKeys.addCommentsHeader) ?? NSOnState
        let mappingModeRawValue = PreferencesKeys.get(setting: .mappingMode) ?? MappingMode.manual.rawValue
        
        parser.parse(text: text, addCommentsHeader: shouldAddCommentsHeader == NSOnState, indentSpaces: PreferencesKeys.get(setting: .indentationSpaces) ?? 4, mappingMode: MappingMode(rawValue: mappingModeRawValue)!)
    }
    
    @IBAction func saveFileDesktopButtonWasTapped(_ sender: AnyObject) {
        if let text = parsedTextView.string {
            parser.createFile(text)
        }
    }
    
    @IBAction func helpButtonWasTapped(_ sender: NSButton) {
        let alert = NSAlert()
        alert.addButton(withTitle: "Got it!")
        alert.informativeText = "- Access the app preferences to configure your settings.\n- Paste the model class from Swagger API docs.\n- Tap on Parse button.\n- Check the parsed text is ok or modify it.\n- Tap on Save File in Desktop."
        alert.messageText = "How to use this app"
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    // MARK: - Helpers
    
    func createWarningAlert(message: String, informative: String = "") {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImageNameCaution)
        alert.messageText = message
        alert.informativeText = informative
        if let window = self.view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
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
        createWarningAlert(message: error)
    }
    
    func parseDidFail(_ error: String, hint: String) {
        createWarningAlert(message: error, informative: hint)
    }
}
