//
//  Parser.swift
//  Rosetta
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 25/08/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Foundation
import Cocoa

enum BuiltinDataTypes: String {
    case int, uint, float, double, bool, string, character, optional
}

enum ParsedVariableTypes: String {
    case number, integer, boolean

    static func convertToFinalType(providedType : String) -> String {
        if let varType = ParsedVariableTypes(rawValue: providedType) {
            switch varType {
            case .number:
                return BuiltinDataTypes.double.rawValue.capitalized
            case .integer:
                return BuiltinDataTypes.int.rawValue.capitalized
            case .boolean:
                return BuiltinDataTypes.bool.rawValue.capitalized
            }
        }
        
        return providedType
    }
}

protocol ParserDelegate : class {
    func parseDidSuccess(_ parsedString: String)
    func parseDidFail(_ error : String, hint: String)
    func parseDidFail(_ error : String)
}

class Parser {
    var indentSpaces: Int!
    var mappingMode: MappingMode!
    var modelTuplesArray: [(varName: String, varType: String, enumValues: [String]?)]!
    var parsedString: String!
    var className: String!
    weak var delegate: ParserDelegate?
    let inlineComment = "//"
    let newLine = "\n"
    let doubleSpace = "  "
    
    required init(delegate: ParserDelegate) {
        self.delegate = delegate        
    }
    
    func parse(text: String, addCommentsHeader: Bool, indentSpaces: Int, mappingMode: MappingMode) {
        
        var components = text.components(separatedBy: CharacterSet(charactersIn: "{}"))
        components = components.filter{!$0.isEmpty}.map{$0.trimmingCharacters(in: .whitespaces)}
        
        guard components.count == 2 else { // [0] = className, [1] = body
            self.delegate?.parseDidFail("The format of the model provided is not correct", hint: "Ensure the format matches the data type from Swagger.")
            return
        }
        
        self.className = components[0]
        self.indentSpaces = indentSpaces
        self.mappingMode = mappingMode
        self.parsedString = ""
        
        if addCommentsHeader {
            createFileHeader()
        }
        
        createFileImports()
        createBody(body: components[1])
    }
    
    
    /// Creates the commented header with the file name, project name, author and company
    func createFileHeader() {
        
        var comments = inlineComment + newLine + inlineComment + doubleSpace + className! + ".swift" + newLine
        
        if let projectName: String = PreferencesKeys.get(setting: .projectName),
            !projectName.isEmpty {
            comments += inlineComment + doubleSpace + projectName + newLine
        }
        
        comments += inlineComment + newLine + inlineComment + doubleSpace + "Created "
        if let author: String = PreferencesKeys.get(setting: .author),
            !author.isEmpty {
            comments += "by \(author) "
        }
        
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        comments += "on \(date)"
        
        if let companyName: String = PreferencesKeys.get(setting: .companyName),
            !companyName.isEmpty {
            comments += newLine + inlineComment + doubleSpace + "Copyright © "
            comments += date.substring(with: date.index(date.startIndex, offsetBy: 6)..<date.endIndex) + " " + companyName + ". All rights reserved."
        }
        
        comments += newLine + inlineComment + newLine + newLine
        
        parsedString! += comments
    }
    
    /// Adds the needed imports depending on the chosen mapping
    func createFileImports() {
        
        switch mappingMode! {
        case .objectmapper:
            parsedString! += "import ObjectMapper" + newLine + newLine
        case .manual:
            parsedString! += "import Foundation" + newLine + newLine
        case .freddy, .gloss, .swiftyJSON:
            // TODO: Work on this
            break
        }
    }
    
    /// Parse the body of the model. Contains the mapping of enums and implementation
    ///
    /// - Parameter body: model before parsing
    func createBody(body: String) {
        
        // TODO: Parse array inside the objects, e.g. user {wifeNames:["ana", "scarlett", "susan"]}
        // TODO: Parse classes inside the objects
        
        modelTuplesArray = []
        
        let lines: [String] = body.components(separatedBy: .newlines).filter{ !$0.isEmpty }
        
        for line in lines {
            if let tuple = self.parseLine(String(line.characters.filter{ !" \t\r".characters.contains($0) })) {
                modelTuplesArray.append(tuple)
            } else {
                self.delegate?.parseDidFail("Cannot parse line. Invalid format provided", hint: "The following line: \(line) does not seems to have a valid format.")
                
                return
            }
        }
        
        let enumTuples = modelTuplesArray.filter( { $2 != nil } )
        for enumTuple in enumTuples {
            createFileEnum(enumTuple: (enumTuple.varName, enumTuple.varType, enumTuple.enumValues!))
        }
        
        createFileBody()
        
        self.delegate?.parseDidSuccess(parsedString)
    }
    
    /// Parse each line of the model provided
    ///
    /// - Parameter line: line before mapping
    /// - Returns: tuple containing the variable name, type and posible enum values
    func parseLine(_ line : String) -> (varName: String, varType: String, enumValues: [String]?)? {

        guard let parametersString = line.slice(from: "(", to: ")") else {
            return nil
        }
        
        guard let startParenthesisRange = line.range(of: "("),
            let endParenthesisRange = line.range(of: ")") else {
            return nil
        }
        
        let parametersComponents = parametersString.components(separatedBy: CharacterSet(charactersIn: ",")).filter{ !$0.isEmpty }
        
        var varType: String
        if parametersComponents.isEmpty { // only has the type
            varType = parametersString
        } else {
            varType = parametersComponents.first!
        }
        
        // the type is an array, e.g. tags (Array[Tag], optional),
        if let arrayType = varType.slice(from: "[", to: "]") {
            varType = "[\(arrayType.capitalized)]"
        }
        
        let variableName = line.substring(to: startParenthesisRange.lowerBound)
        let variableType = ParsedVariableTypes.convertToFinalType(providedType: varType)
        var enumValues : [String]?
        
        let restLine = line.substring(from: endParenthesisRange.lowerBound)
        
        if let enumValuesString = restLine.slice(from: "[", to: "]") { // there's an enum
            enumValues = self.parseEnumValues(enumValues: enumValuesString)
        }
        
        return (varName: variableName, varType: variableType.capitalized, enumValues: enumValues)
    }
    
    /// Parse enum values from the string to array of strings
    ///
    /// - Parameter enumValues: enum values in string format
    /// - Returns: array with the enum values in string format
    func parseEnumValues(enumValues : String) -> [String] {
        
        return enumValues.components(separatedBy: CharacterSet(charactersIn: ",")).filter{ !$0.isEmpty }
    }
    
    /// Create enumerations from the line containing var name, var type and enum values
    ///
    /// - Parameter enumTuple: line containing var name, var type and enum values
    func createFileEnum(enumTuple: (name : String, type : String, values : [String])) {
        
        var fileEnum = "enum \(enumTuple.name.capitalized): \(enumTuple.type.capitalized) {\(newLine)"
        
        for enumValue in enumTuple.values {
            fileEnum += indent() + "case "
            
            let enumStringRawValue = self.transformEnumValueStyle(enumValue: enumValue)
            
            fileEnum += enumStringRawValue + " = " + enumValue.replacingOccurrences(of: "'", with: "\"") + newLine
        }
        
        parsedString! += fileEnum + "}" + newLine + newLine
    }
    
    /// Create final parsed file
    ///
    /// - Parameter text: Text to include in the file (from the parsed text view)
    func createFile(_ text : String) {
        
        let filename = getDesktopDirectory().appending("/" + className! + ".swift")
        do {
            try text.write(toFile: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            self.delegate?.parseDidFail("Cannot create file", hint: "Bad permissions, bad filename, missing permissions or the encoding failed.")
        }
    }
    
    /// Create body based on the chosen mapping mode
    ///
    /// - Returns:
    func createFileBody() {
        
        switch mappingMode! {
        case .objectmapper:
            createBodyObjectMapper()
        default:
            // TODO: Add more mapping modes
            createBodyManual()
        }
    }
    
    func createBodyObjectMapper() {
        
        var fileBody = "public class \(className!): Mappable {\(newLine)"
        createVariableDeclarations(body: &fileBody)
        
        fileBody += newLine + indent() + "init() {\(newLine)\(indent())}\(newLine)\(newLine)\(indent())required public init?(_ map: Map) {\(newLine)\(indent())}\(newLine)\(newLine)\(indent())public func mapping(map: Map) {\(newLine)"
        
        for modelTuple in modelTuplesArray {
            fileBody += indent(level: 2) + modelTuple.varName + " <- map[\"" + modelTuple.varName + "\"]\(newLine)"
        }
        
        fileBody += indent() + "}\(newLine)}\(newLine)"
        
        parsedString! += fileBody
    }
    
    func createBodyManual() {
        
        var fileBody = "public class \(className!): NSObject {\(newLine)"
        createVariableDeclarations(body: &fileBody)
        
        fileBody += newLine + indent() + "func map(array: [AnyObject]) -> [\(className!)] {" + newLine + indent(level: 2)
        fileBody += "var mappedArray = [\(className!)]()\(newLine)" + indent(level: 2)
        fileBody += "for element in array {\(newLine)" + indent(level: 3)
        fileBody += "if let dictionary = element as? [String: Any] {\(newLine)" + indent(level: 4)
        fileBody += "let \(className!.lowercased()) = \(className!)()\(newLine)" + indent(level: 4)
        fileBody += "\(className!.lowercased()).map(dictionary: dictionary)\(newLine)" + indent(level: 4)
        fileBody += "mappedArray.append(\(className!.lowercased()))\(newLine)" + indent(level: 3)
        fileBody += "}\(newLine)" + indent(level: 2)
        fileBody += "}\(newLine)\(newLine)" + indent(level: 2)
        fileBody += "return mappedArray\n" + indent() + "}\(newLine)\(newLine)" + indent()
        
        fileBody += "func map(dictionary: [String: Any]) {\(newLine)"
        
        for modelTuple in modelTuplesArray {
            fileBody += indent(level: 2)
            if modelTuple.enumValues != nil {
                fileBody += "self.\(modelTuple.varName) = \(modelTuple.varName.capitalized)(rawValue: dictionary[\"\(modelTuple.varName)\"] as? \(modelTuple.varType))\(newLine)"
            } else {
                
                // TODO: Clean this and check if this works on ObjectMapper
                // we need to check if we are treating an array of custom objects
                if let type = modelTuple.varType.slice(from: "[", to: "]") {
                    if BuiltinDataTypes(rawValue: type.lowercased()) == nil {
                        // array of custom types
                        
                        fileBody += "if let \(modelTuple.varName)Array = dictionary[\"\(modelTuple.varName)\"] as? [AnyObject] {\(newLine)"
                        fileBody += indent(level: 3) + "self.\(modelTuple.varName) = \(type)().map(array: \(modelTuple.varName)Array)" + newLine + indent(level: 2) + "}" + newLine
                    } else {
                        // it's an array of builtin types
                        fileBody += "self.\(modelTuple.varName) = dictionary[\"\(modelTuple.varName)\"] as? \(modelTuple.varType)\(newLine)"
                    }
                    
                } else if BuiltinDataTypes(rawValue: modelTuple.varType.lowercased()) == nil {
                    // dictionary of custom types
                    
                    fileBody += "if let \(modelTuple.varName)Dictionary = dictionary[\"\(modelTuple.varName)\"] as? [String: AnyObject] {\(newLine)"
                    fileBody += indent(level: 3) + "self.\(modelTuple.varName) = \(modelTuple.varType)().map(dictionary: \(modelTuple.varName)Dictionary)" + newLine + indent(level: 2) + "}" + newLine
                } else {
                    // it's a builtin type
                    fileBody += "self.\(modelTuple.varName) = dictionary[\"\(modelTuple.varName)\"] as? \(modelTuple.varType)\(newLine)"
                }
            }
        }
        
        fileBody += indent() + "}\(newLine)}\(newLine)"
        
        parsedString! += fileBody
    }
    
    func createVariableDeclarations(body: inout String) {
        for modelTuple in modelTuplesArray {
            body += "\(indent())var \(modelTuple.varName): "
            
            if modelTuple.enumValues != nil {
                body += modelTuple.varName.capitalized
            } else {
                body += modelTuple.varType
            }
            
            body += "?\(newLine)"
        }
    }
}

extension Parser { // Helpers
    
    func indent(level: Int = 1) -> String {
        return String(repeating: " ", count: level * indentSpaces)
    }
    
    func getDesktopDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    /// Loops through the next character of every underscore to uppercase it and remove the underscore symbol (PLAY_AGAIN -> playAgain)
    ///
    /// - Parameter enumValue: original enum value from the model
    func transformEnumValueStyle(enumValue: String) -> String {
        var enumStringRawValue = enumValue.replacingOccurrences(of: "'", with: "").lowercased()
        var underscoreRange = enumStringRawValue.range(of: "_")
        
        while underscoreRange != nil {
            let nextCharacterIndex = enumStringRawValue.index(after: underscoreRange!.lowerBound)
            let nextCharacterRange = nextCharacterIndex ..< enumStringRawValue.index(after: nextCharacterIndex)
            let nextCharacter = enumStringRawValue.substring(with: nextCharacterRange)
            
            enumStringRawValue.replaceSubrange(nextCharacterRange, with: nextCharacter.uppercased())
            enumStringRawValue.replaceSubrange(underscoreRange!, with: "")
            underscoreRange = enumStringRawValue.range(of: "_")
        }
        
        return enumStringRawValue
    }
}

extension String {
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                substring(with: substringFrom..<substringTo)
            }
        }
    }
}
