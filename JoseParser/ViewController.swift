//
//  ViewController.swift
//  JoseParser
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 25/08/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextStorageDelegate, ParserDelegate {
    @IBOutlet var parserTextView: NSTextView!
    @IBOutlet var parsedTextView: NSTextView!
    @IBOutlet weak var authorTextField: NSTextField!
    @IBOutlet weak var companyTextField: NSTextField!
    @IBOutlet weak var projectNameTextField: NSTextField!
    @IBOutlet weak var parseButton: NSButton!
    @IBOutlet weak var saveFileToDeskopButton: NSButton!
    let parser = Parser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTextFields()
        self.setupTextViews()
    }
    
    // MARK: - Setup
    
    func setupTextFields() {
        if let author = NSUserDefaults.standardUserDefaults().objectForKey("Author") {
            authorTextField.stringValue = author as! String
        }
        
        if let company = NSUserDefaults.standardUserDefaults().objectForKey("Company") {
            companyTextField.stringValue = company as! String
        }
        
        if let projectName = NSUserDefaults.standardUserDefaults().objectForKey("ProjectName") {
            projectNameTextField.stringValue = projectName as! String
        }
    }
    
    func setupTextViews() {
        self.parserTextView.textStorage?.delegate = self
        self.parsedTextView.textStorage?.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func parseButtonWasTapped(sender: AnyObject) {
        if let text = parserTextView.string {
            parser.parse(text, author: authorTextField.stringValue, company: companyTextField.stringValue, projectName: projectNameTextField.stringValue, delegate: self)
        }
    }
    
    @IBAction func saveFileDesktopButtonWasTapped(sender: AnyObject) {
        if let text = parsedTextView.string {
            parser.createFile(text)
        }
    }
    
    @IBAction func helpButtonWasTapped(sender: NSButton) {
        let alert = NSAlert()
        alert.addButtonWithTitle("Got it!")
        alert.informativeText = "- Paste the model class from Swagger API docs.\n- Tap on Parse button.\n- Check the parsed text is ok or modify it.\n- Tap on Save File in Desktop."
        alert.messageText = "How to use this app"
        alert.beginSheetModalForWindow(self.view.window!) { modalResponse in
            print("hello")
        }
    }
    
    // MARK: - NSTextStorageDelegate
    
    override func textStorageDidProcessEditing(notification: NSNotification) {
        parseButton.enabled = parserTextView.string?.characters.count > 0
        saveFileToDeskopButton.enabled = parsedTextView.string?.characters.count > 0
    }
    
    // MARK: - ParserDelegate
    
    func parserDidSuccess(parsedString: String) {
        parsedTextView.string = parsedString
    }
    
    func parseDidFail(error: String) {
        NSBeep()
    }
}

