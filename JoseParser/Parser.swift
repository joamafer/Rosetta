//
//  Parser.swift
//  JoseParser
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 25/08/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Foundation
import Cocoa

enum VariableTypes: String {
    case number, integer, boolean

    static func getFinalType(_ variableType : String) -> String {
        
        if let varType = VariableTypes(rawValue: variableType) {
            switch varType {
            case .number:
                return "Double"
            case .integer:
                return "Int"
            case .boolean:
                return "Bool"
            }
        }
        
        return variableType
    }
}

protocol ParserDelegate : class {
    func parseDidSuccess(_ parsedString: String)
    func parseDidFail(_ error : String)
}

class Parser {
    var className: String!
    var modelVariables: [(varName: String, varType: String, enumValues: [String]?)]!
    var parsedString: String!
    var mappingMode: MappingMode!
    weak var delegate: ParserDelegate?
    
    required init(delegate: ParserDelegate) {
        self.delegate = delegate
    }
    
    func parse(textToParse: String) {
        
        guard let mappingMode = MappingMode(rawValue:PreferencesKeys.get(setting: PreferencesKeys.mappingMode) ?? "") else {
            return
        }
        
        self.mappingMode = mappingMode
        self.modelVariables = []
        self.parsedString = ""
        
        let fileComponents = textToParse.components(separatedBy: CharacterSet(charactersIn: "{}")).filter { !$0.isEmpty }
        
        guard fileComponents.count == 2 else {
            self.delegate?.parseDidFail("The format of the model provided is not correct")
            return
        }
        
        self.className = fileComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let state: Int = PreferencesKeys.get(setting: .addCommentsHeader),
            state != NSOnState {
        } else {
            createFileHeader(header: fileComponents[0])
        }
        
        createFileImports()
        createBody(body: fileComponents[1])
        
        self.delegate?.parseDidSuccess(parsedString)
    }
    
    /// Creates the comment code about the project name, author, company name and copyright
    ///
    /// - Parameter header: String not parsed which contains the class name
    func createFileHeader(header: String) {
        
        var fileInfo = "//\n//  " + className + ".swift\n"
        
        let projectName = PreferencesKeys.get(setting: .projectName) ?? ""
        let author = PreferencesKeys.get(setting: .author) ?? ""
        let companyName = PreferencesKeys.get(setting: .companyName) ?? ""
        
        if !projectName.isEmpty {
            fileInfo = fileInfo + "//  \(projectName)\n"
        }
        fileInfo = fileInfo + "//\n//  Created"
        
        if !author.isEmpty {
            fileInfo = fileInfo + " by \(author)"
        }
        
        fileInfo = fileInfo + " on "
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        fileInfo = fileInfo + "\(date)\n"
        
        if !companyName.isEmpty {
            fileInfo = fileInfo + "//  Copyright © "
            
            let start = date.index(date.startIndex, offsetBy: 6)
            let end = date.endIndex
            
            fileInfo = fileInfo + date.substring(with: start..<end) + " "
            fileInfo = fileInfo + companyName
            fileInfo = fileInfo + ". All rights reserved.\n//\n\n"
        }
        
        parsedString = fileInfo
    }
    
    /// Create file imports needed depending on the mapping the user choose
    func createFileImports() {
        
        switch mappingMode! {
        case .objectmapper:
            parsedString = parsedString + "import ObjectMapper\n\n"
        case .manual:
            break
        case .freddy, .gloss, .swiftyJSON:
            // TODO: Work on this
            break
        }
    }
    
    /// Parse the body of the model. Contains the mapping of enums and implementation
    ///
    /// - Parameter body: model before parsing
    func createBody(body: String) {
        let lines: [String] = body.components(separatedBy: .newlines).filter{ !$0.isEmpty }
        
        for line in lines {
            if let tuple = self.parseLine(String(line.characters.filter{ !" \n\t\r".characters.contains($0) })) {
                modelVariables.append(tuple)
            }
        }
        
        let enumTuples = modelVariables.filter( { $2 != nil } )
        for enumTuple in enumTuples {
            parsedString = parsedString + self.createFileEnum((enumTuple.0, enumTuple.1, enumTuple.2!))
        }
        
        parsedString = parsedString + self.createFileBody()
    }
    
    func parseLine(_ line : String) -> (varName: String, varType: String, enumValues: [String]?)? {
        
        let customCharacterSet = CharacterSet(charactersIn: "(,")
        let lineComponents = line.components(separatedBy: customCharacterSet).filter{ !$0.isEmpty }
        
        guard lineComponents.count > 2 else {
            self.delegate?.parseDidFail("Cannot parse line")
            return nil
        }
        
        let variableName = lineComponents[0]
        let variableType = VariableTypes.getFinalType(lineComponents[1])
        var enumValues : [String]?
        
        if lineComponents.count > 3 { // line is an enum
            
            let customCharacterSet = CharacterSet(charactersIn: "[]")
            let enumComponents = line.components(separatedBy: customCharacterSet).filter{ !$0.isEmpty }
            
            if enumComponents.count == 3 {
                enumValues = self.parseEnumValues(enumComponents[1])
            }
        }
        
        return (varName: variableName, varType: variableType, enumValues: enumValues)
    }
    
    func parseEnumValues(_ lineWithEnum : String) -> [String] {
        let squareBracketsCharacterSet = CharacterSet(charactersIn: ",")
        
        return lineWithEnum.components(separatedBy: squareBracketsCharacterSet).filter{ $0 != "," && !$0.isEmpty }
    }
    
    func createFile(_ text : String) {
        let filename = getDesktopDirectory().appending(className + ".swift")
        
        do {
            try text.write(toFile: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            self.delegate?.parseDidFail("Bad permissions, bad filename, missing permissions or the encoding failed")
        }
    }
    
    func createFileEnum(_ tuple: (enumName : String, enumType : String, enumValues : [String])) -> String {
        var fileEnum = ("enum ")
        
        fileEnum = fileEnum + tuple.enumName
        fileEnum = fileEnum + ": "
        fileEnum = fileEnum + tuple.enumType.capitalized
        fileEnum = fileEnum + " {\n"
        
        for enumValue in tuple.enumValues {
            fileEnum = fileEnum + indent() + "case "
            
            var enumValueDoubleQuotes = enumValue.replacingOccurrences(of: "'", with: "").lowercased()
            
            var underscoreRange = enumValueDoubleQuotes.range(of: "_")
            
            while underscoreRange != nil {
                let nextCharacterIndex = enumValueDoubleQuotes.index(after: underscoreRange!.lowerBound)
                let nextCharacterRange = nextCharacterIndex ..< enumValueDoubleQuotes.index(after: nextCharacterIndex)
                let nextCharacter = enumValueDoubleQuotes.substring(with: nextCharacterRange)
                enumValueDoubleQuotes.replaceSubrange(nextCharacterRange, with: nextCharacter.uppercased())
                enumValueDoubleQuotes.replaceSubrange(underscoreRange!, with: "")
                underscoreRange = enumValueDoubleQuotes.range(of: "_")
            }
            
            fileEnum = fileEnum + enumValueDoubleQuotes
            fileEnum = fileEnum + " = "
            fileEnum = fileEnum + enumValue.replacingOccurrences(of: "'", with: "\"")
            fileEnum = fileEnum + "\n"
        }
        
        return fileEnum + "}\n\n"
    }
    
    func createFileBody() -> String {
        
        switch mappingMode! {
        case .objectmapper:
            return createBodyObjectMapper()
        default:
            return createBodyManual()
        }
    }
    
    func createVariableDeclarations(body: String) -> String {
        var fileBody = body
        for i in 0 ..< modelVariables.count {
            fileBody = fileBody + "\(indent())var "
            fileBody = fileBody + (modelVariables[i].0)
            fileBody = fileBody + ": "
            
            if modelVariables[i].2 != nil {
                fileBody = fileBody + modelVariables[i].0.capitalized + "?\n"
            } else {
                fileBody = fileBody + (modelVariables[i].1.capitalized) + "?\n"
            }
        }
        
        return fileBody
    }
    
    func createBodyObjectMapper() -> String {
        var fileBody = "public class "
        fileBody = fileBody + className
        fileBody = fileBody + ": Mappable {\n"
        
        fileBody = createVariableDeclarations(body: fileBody)
        
        fileBody = fileBody + "\n\(indent())init() {\n\(indent())}\n\n\(indent())required public init?(_ map: Map) {\n\(indent())}\n\n\(indent())public func mapping(map: Map) {\n"
        
        for tuple in modelVariables {
            fileBody = fileBody + indent(level: 2)
            fileBody = fileBody + (tuple.0)
            fileBody = fileBody + " <- map[\""
            fileBody = fileBody + (tuple.0)
            fileBody = fileBody + "\"]\n"
        }
        
        fileBody = fileBody + indent() + "}\n}\n"
        
        return fileBody
    }
    
    func createBodyManual() -> String {
        var fileBody = "public class "
        fileBody = fileBody + className
        fileBody = fileBody + ": NSObject {\n"
        
        fileBody = createVariableDeclarations(body: fileBody)
        
        fileBody = fileBody + "\n\(indent())func mapArray(mappingArray: [AnyObject]) -> [\(className!)] {\n" + indent(level: 2)
        fileBody = fileBody + "var mapArray = [\(className!)]()\n" + indent(level: 2)
        fileBody = fileBody + "for mappingObject in mappingArray {\n" + indent(level: 3)
        fileBody = fileBody + "if let mapping\(className!) = mappingObject as? [String: Any] {\n" + indent(level: 4)
        fileBody = fileBody + "let \(className!.lowercased()) = \(className!)()\n" + indent(level: 4)
        fileBody = fileBody + "\(className!.lowercased()).map(mappingObject: mapping\(className!))\n" + indent(level: 4)
        fileBody = fileBody + "mapArray.append(\(className!.lowercased()))\n" + indent(level: 3)
        fileBody = fileBody + "}\n" + indent(level: 2)
        fileBody = fileBody + "}\n\n" + indent(level: 2)
        fileBody = fileBody + "return mapArray\n" + indent(level: 1) + "}\n\n" + indent(level: 1)
        
        fileBody = fileBody + "private func map(mappingObject: [String: Any]) {\n"
        
        for tuple in modelVariables {
            fileBody = fileBody + indent(level: 2)
            fileBody = fileBody + "if let " + (tuple.0) + " = mappingObject[\"\((tuple.0))\"] as? \(tuple.1.capitalized) {\n" + indent(level: 3)
            fileBody = fileBody + "self.\((tuple.0)) = \((tuple.0))\n" + indent(level: 2)
            fileBody = fileBody + "}\n"
        }
        
        fileBody = fileBody + indent() + "}\n}\n"
        
        return fileBody
    }
}

extension Parser { // Helpers
    
    func indent(level: Int = 1) -> String {
        return String(repeating: " ", count: level * PreferencesKeys.get(setting: .indentationSpaces)!)
    }
    
    func getDesktopDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
}
