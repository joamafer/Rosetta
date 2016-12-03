//
//  Parser.swift
//  JoseParser
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 25/08/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import Foundation

enum VariableTypes : String {
    case Number = "number"
    case Integer = "integer"
    case Boolean = "boolean"

    static func convertVariableType(_ variableType : String) -> String {
        var finalType = variableType
        
        if let specialVariableType = VariableTypes(rawValue: variableType) {
        
            switch specialVariableType {
            case .Number:
                finalType = "Double"
            case .Integer:
                finalType = "Int"
            case .Boolean:
                finalType = "Bool"
            }
        }
        
        return finalType.capitalized
    }
}

protocol ParserDelegate : class {
    func parserDidSuccess(_ parsedString: String)
    func parseDidFail(_ error : String)
}

class Parser {
    var className : String!
    var variables : [(String, String, [String]?)] = []
    var parsedString = ""
    weak var delegate : ParserDelegate?
    
    func parse(_ text: String, author: String, company: String, projectName: String, delegate: ParserDelegate) {
        
        self.className = ""
        self.variables = []
        self.parsedString = ""
        self.delegate = nil
        
        self.delegate = delegate
        
        UserDefaults.standard.set(author, forKey: "Author")
        UserDefaults.standard.set(company, forKey: "Company")
        UserDefaults.standard.set(projectName, forKey: "ProjectName")
        
        let curlyBracketsCharacterSet = CharacterSet(charactersIn: "{}")
        let fileComponents = text.components(separatedBy: curlyBracketsCharacterSet).filter {$0 != ""}
        
        if fileComponents.count == 2 {
            self.className = fileComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
            
            let lines : [String] = fileComponents[1].components(separatedBy: .newlines).filter {$0 != ""}
            
            for line in lines {
                if let tuple = self.parseLine(line.replacingOccurrences(of: " ", with: "")) {
                    variables.append(tuple)
                }
            }
            
            parsedString = self.createFileInfo(author, company: company, projectName: projectName)
            let enumTuples = variables.filter( { $2 != nil } )
            for enumTuple in enumTuples {
                parsedString = parsedString + self.createFileEnum((enumTuple.0, enumTuple.1, enumTuple.2!))
            }
            
            parsedString = parsedString + self.createFileBody(variables)
            
            self.delegate?.parserDidSuccess(parsedString)
            
        } else {
            self.delegate?.parseDidFail("The format of the model is not correct")
        }
    }
    
    func parseLine(_ line : String) -> (String, String, [String]?)? {
        
        let customCharacterSet = CharacterSet(charactersIn: "(,")
        let lineComponents = line.components(separatedBy: customCharacterSet).filter{ $0 != ""}
        
        if lineComponents.count > 2 {
            
            let variableName = lineComponents[0]
            let variableType = VariableTypes.convertVariableType(lineComponents[1])
            var enumValues : [String]?
            
            if lineComponents.count > 3 { // enum
                
                let customCharacterSet = CharacterSet(charactersIn: "[]")
                let enumComponents = line.components(separatedBy: customCharacterSet).filter{ $0 != ""}
                
                if enumComponents.count == 3 {
                    enumValues = self.parseEnum(enumComponents[1])
                }
            }
            
            return (variableName, variableType, enumValues)
            
        } else {
            self.delegate?.parseDidFail("Cannot parse line")
            
            return nil
        }
    }
    
    func parseEnum(_ lineWithEnum : String) -> [String] {
        let squareBracketsCharacterSet = CharacterSet(charactersIn: ",")
        return lineWithEnum.components(separatedBy: squareBracketsCharacterSet).filter{ $0 != "," && $0 != "" }
    }
    
    // MARK: - File creation
    
    func createFile(_ text : String) {
        let filename = getDesktopDirectory().appendingPathComponent(className + ".swift")
        
        do {
            try text.write(toFile: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            self.delegate?.parseDidFail("Bad permissions, bad filename, missing permissions or the encoding failed")
        }
    }
    
    func createFileInfo(_ author: String, company: String, projectName: String) -> String {
        var fileInfo = "//\n//  " + className + ".swift\n"
        
        if projectName.characters.count > 0 {
            fileInfo = fileInfo + "//  \(projectName)\n"
        }
        fileInfo = fileInfo + "//\n//  Created"
        
        if author.characters.count > 0 {
            fileInfo = fileInfo + " by \(author)"
        }
        
        fileInfo = fileInfo + " on "
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        fileInfo = fileInfo + "\(date)\n"
        
        if company.characters.count > 0 {
            fileInfo = fileInfo + "//  Copyright © "
            fileInfo = fileInfo + date[date.characters.index(date.startIndex, offsetBy: 6)..<date.characters.index(date.startIndex, offsetBy: 10)] + " "
            fileInfo = fileInfo + company
            fileInfo = fileInfo + ". All rights reserved.\n"
        }
        
        fileInfo = fileInfo + "//\n\nimport ObjectMapper\n\n"
        
        return fileInfo
    }
    
    func createFileEnum(_ tuple: (enumName : String, enumType : String, enumValues : [String])) -> String {
        var fileEnum = ("enum ")
        
        let firstCharacterRange = tuple.enumName.characters.index(tuple.enumName.startIndex, offsetBy: 0)..<tuple.enumName.characters.index(tuple.enumName.startIndex, offsetBy: 1)
        let enumNameFirstCharacter = tuple.enumName.substring(with: firstCharacterRange)
        var enumName = tuple.enumName
        enumName.replaceSubrange(firstCharacterRange, with: enumNameFirstCharacter.uppercased())
        
        fileEnum = fileEnum + enumName
        fileEnum = fileEnum + ": "
        fileEnum = fileEnum + (tuple.enumType)
        fileEnum = fileEnum + " {\n"
        
        for enumValue in tuple.enumValues {
            fileEnum = fileEnum + "    case "
            
            var enumValueDoubleQuotes = enumValue.replacingOccurrences(of: "'", with: "").lowercased()
            
            var underscoreRange = enumValueDoubleQuotes.range(of: "_")
            
            while underscoreRange != nil {
                let nextCharacterRange = enumValueDoubleQuotes.index(underscoreRange!.lowerBound, offsetBy: 1) ..< enumValueDoubleQuotes.index(underscoreRange!.lowerBound, offsetBy: 2)
                let nextCharacter = enumValueDoubleQuotes.substring(with: nextCharacterRange)
                enumValueDoubleQuotes.replaceSubrange(nextCharacterRange, with: nextCharacter.uppercased())
                enumValueDoubleQuotes.replaceSubrange(underscoreRange!, with: "")
                underscoreRange = enumValueDoubleQuotes.range(of: "_")
            }
            
            enumValueDoubleQuotes.replaceSubrange(enumValueDoubleQuotes.characters.index(enumValueDoubleQuotes.startIndex, offsetBy: 0) ..< enumValueDoubleQuotes.characters.index(enumValueDoubleQuotes.startIndex, offsetBy: 1), with: enumValueDoubleQuotes.substring(to: enumValueDoubleQuotes.characters.index(enumValueDoubleQuotes.startIndex, offsetBy: 1)).uppercased())
            
            fileEnum = fileEnum + enumValueDoubleQuotes
            fileEnum = fileEnum + " = "
            fileEnum = fileEnum + enumValue.replacingOccurrences(of: "'", with: "\"")
            fileEnum = fileEnum + "\n"
        }
        
        return fileEnum + "}\n\n"
    }
    
    func createFileBody(_ variables: [(String, String, [String]?)]) -> String {
        
        var fileBody = "public class "
        fileBody = fileBody + className
        fileBody = fileBody + ": Mappable {\n\n"
        
        for i in 0..<variables.count {
            fileBody = fileBody + "    var "
            fileBody = fileBody + (variables[i].0)
            fileBody = fileBody + ": "
            
            if variables[i].2 != nil {
                fileBody = fileBody + variables[i].0.setFirstLetterUppercase() + "?\n"
            } else {
                fileBody = fileBody + (variables[i].1) + "?\n"
            }
        }

        fileBody = fileBody + "\n    init() {\n    }\n\n    required public init?(_ map: Map) {\n\n    }\n\n    public func mapping(map: Map) {\n"
        
        for tuple in variables {
            fileBody = fileBody + "        "
            fileBody = fileBody + (tuple.0)
            fileBody = fileBody + " <- map[\""
            fileBody = fileBody + (tuple.0)
            fileBody = fileBody + "\"]\n"
        }

        fileBody = fileBody + "    }\n}\n"
        
        return fileBody
    }
    
    // MARK: - Helpers
    
    func getDesktopDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
}

extension String {
    func setFirstLetterUppercase() -> String {
        let firstCharacterRange = self.characters.index(self.startIndex, offsetBy: 0)..<self.characters.index(self.startIndex, offsetBy: 1)
        let enumNameFirstCharacter = self.substring(with: firstCharacterRange)
        var enumName = self
        enumName.replaceSubrange(firstCharacterRange, with: enumNameFirstCharacter.uppercased())
        return enumName
    }
}
