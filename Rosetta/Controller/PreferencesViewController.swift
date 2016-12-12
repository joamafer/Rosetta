//
//  PreferencesViewController.swift
//  Rosetta
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 20/11/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {
    @IBOutlet weak var addHeaderCommentsButton: NSButton!
    @IBOutlet weak var jsonMappingButton: NSPopUpButton!
    dynamic var spacesIndentationValue: NSNumber!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        saveConfiguration()
    }
    
    // MARK: - Setup
    
    func setupUI() {
        jsonMappingButton.addItems(withTitles: MappingMode.allValues)
        jsonMappingButton.selectItem(withTitle: PreferencesKeys.get(setting: .mappingMode) ?? MappingMode.manual.rawValue)
        addHeaderCommentsButton.state = PreferencesKeys.get(setting: .addCommentsHeader) ?? NSOnState
        spacesIndentationValue = PreferencesKeys.get(setting: .indentationSpaces) ?? 4
    }
    
    // MARK: - Actions
    
    func saveConfiguration() {
        PreferencesKeys.set(setting: .addCommentsHeader, value: addHeaderCommentsButton.state)
        PreferencesKeys.set(setting: .indentationSpaces, value: spacesIndentationValue)
        PreferencesKeys.set(setting: .mappingMode, value: jsonMappingButton.titleOfSelectedItem)
        
        NotificationCenter.default.post(name: .preferencesUpdated, object: nil)
    }
}
