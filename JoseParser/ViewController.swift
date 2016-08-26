//
//  ViewController.swift
//  JoseParser
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 25/08/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var parserTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func parseButtonWasTapped(sender: AnyObject) {
        if let textStorage = parserTextView.textStorage {
            Parser().parse(textStorage.string)
        }
    }
    

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

