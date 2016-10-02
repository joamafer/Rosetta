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

    static func convertVariableType(variableType : String) -> String {
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
        
        return finalType.capitalizedString
    }
}

protocol ParserDelegate : class {
    func parserDidSuccess(parsedString: String)
    func parseDidFail(error : String)
}

class Parser {
    var className : String!
    var variables : [(String, String, [String]?)] = []
    var parsedString = ""
    weak var delegate : ParserDelegate?
    
    func parse(text: String, author: String, company: String, projectName: String, delegate: ParserDelegate) {
        
        self.className = ""
        self.variables = []
        self.parsedString = ""
        self.delegate = nil
        
        self.delegate = delegate
        
        NSUserDefaults.standardUserDefaults().setObject(author, forKey: "Author")
        NSUserDefaults.standardUserDefaults().setObject(company, forKey: "Company")
        NSUserDefaults.standardUserDefaults().setObject(projectName, forKey: "ProjectName")
        
        let curlyBracketsCharacterSet = NSCharacterSet(charactersInString: "{}")
        let fileComponents = text.componentsSeparatedByCharactersInSet(curlyBracketsCharacterSet).filter {$0 != ""}
        
        if fileComponents.count == 2 {
            self.className = fileComponents[0].stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
            
            let lines : [String] = fileComponents[1].componentsSeparatedByCharactersInSet(.newlineCharacterSet()).filter {$0 != ""}
            
            for line in lines {
                if let tuple = self.parseLine(line.stringByReplacingOccurrencesOfString(" ", withString: "")) {
                    variables.append(tuple)
                }
            }
            
            parsedString = self.createFileInfo(author, company: company, projectName: projectName)
            let enumTuples = variables.filter( { $2 != nil } )
            for enumTuple in enumTuples {
                parsedString = parsedString.stringByAppendingString(self.createFileEnum((enumTuple.0, enumTuple.1, enumTuple.2!)))
            }
            
            parsedString = parsedString.stringByAppendingString(self.createFileBody(variables))
            
            self.delegate?.parserDidSuccess(parsedString)
            
        } else {
            self.delegate?.parseDidFail("The format of the model is not correct")
        }
    }
    
    func parseLine(line : String) -> (String, String, [String]?)? {
        
        let customCharacterSet = NSCharacterSet(charactersInString: "(,")
        let lineComponents = line.componentsSeparatedByCharactersInSet(customCharacterSet).filter{ $0 != ""}
        
        if lineComponents.count > 2 {
            
            let variableName = lineComponents[0]
            let variableType = VariableTypes.convertVariableType(lineComponents[1])
            var enumValues : [String]?
            
            if lineComponents.count > 3 { // enum
                
                let customCharacterSet = NSCharacterSet(charactersInString: "[]")
                let enumComponents = line.componentsSeparatedByCharactersInSet(customCharacterSet).filter{ $0 != ""}
                
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
    
    func parseEnum(lineWithEnum : String) -> [String] {
        let squareBracketsCharacterSet = NSCharacterSet(charactersInString: ",")
        return lineWithEnum.componentsSeparatedByCharactersInSet(squareBracketsCharacterSet).filter{ $0 != "," && $0 != "" }
    }
    
    // MARK: - File creation
    
    func createFile(text : String) {
        let filename = getDesktopDirectory().stringByAppendingPathComponent(className + ".swift")
        
        do {
            try text.writeToFile(filename, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            self.delegate?.parseDidFail("Bad permissions, bad filename, missing permissions or the encoding failed")
        }
    }
    
    func createFileInfo(author: String, company: String, projectName: String) -> String {
        var fileInfo = "//\n//  " + className + ".swift\n"
        
        if projectName.characters.count > 0 {
            fileInfo = fileInfo.stringByAppendingString("//  \(projectName)\n")
        }
        fileInfo = fileInfo.stringByAppendingString("//\n//  Created")
        
        if author.characters.count > 0 {
            fileInfo = fileInfo.stringByAppendingString(" by \(author)")
        }
        
        fileInfo = fileInfo.stringByAppendingString(" on ")
        let date = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .NoStyle)
        fileInfo = fileInfo.stringByAppendingString("\(date)\n")
        
        if company.characters.count > 0 {
            fileInfo = fileInfo.stringByAppendingString("//  Copyright © ")
            fileInfo = fileInfo.stringByAppendingString(date[date.startIndex.advancedBy(6)..<date.startIndex.advancedBy(10)]) + " "
            fileInfo = fileInfo.stringByAppendingString(company)
            fileInfo = fileInfo.stringByAppendingString(". All rights reserved.\n")
        }
        
        fileInfo = fileInfo.stringByAppendingString("//\n\nimport ObjectMapper\n\n")
        
        return fileInfo
    }
    
    func createFileEnum(tuple: (enumName : String, enumType : String, enumValues : [String])) -> String {
        var fileEnum = ("enum ")
        
        let firstCharacterRange = tuple.enumName.startIndex.advancedBy(0)..<tuple.enumName.startIndex.advancedBy(1)
        let enumNameFirstCharacter = tuple.enumName.substringWithRange(firstCharacterRange)
        var enumName = tuple.enumName
        enumName.replaceRange(firstCharacterRange, with: enumNameFirstCharacter.uppercaseString)
        
        fileEnum = fileEnum.stringByAppendingString(enumName)
        fileEnum = fileEnum.stringByAppendingString(": ")
        fileEnum = fileEnum.stringByAppendingString(tuple.enumType)
        fileEnum = fileEnum.stringByAppendingString(" {\n")
        
        for enumValue in tuple.enumValues {
            fileEnum = fileEnum.stringByAppendingString("    case ")
            
            var enumValueDoubleQuotes = enumValue.stringByReplacingOccurrencesOfString("'", withString: "").lowercaseString
            
            var underscoreRange = enumValueDoubleQuotes.rangeOfString("_")
            
            while underscoreRange != nil {
                let nextCharacterRange = underscoreRange!.startIndex.advancedBy(1) ..< underscoreRange!.startIndex.advancedBy(2)
                let nextCharacter = enumValueDoubleQuotes.substringWithRange(nextCharacterRange)
                enumValueDoubleQuotes.replaceRange(nextCharacterRange, with: nextCharacter.uppercaseString)
                enumValueDoubleQuotes.replaceRange(underscoreRange!, with: "")
                underscoreRange = enumValueDoubleQuotes.rangeOfString("_")
            }
            
            enumValueDoubleQuotes.replaceRange(enumValueDoubleQuotes.startIndex.advancedBy(0) ..< enumValueDoubleQuotes.startIndex.advancedBy(1), with: enumValueDoubleQuotes.substringToIndex(enumValueDoubleQuotes.startIndex.advancedBy(1)).uppercaseString)
            
            fileEnum = fileEnum.stringByAppendingString(enumValueDoubleQuotes)
            fileEnum = fileEnum.stringByAppendingString(" = ")
            fileEnum = fileEnum.stringByAppendingString(enumValue.stringByReplacingOccurrencesOfString("'", withString: "\""))
            fileEnum = fileEnum.stringByAppendingString("\n")
        }
        
        return fileEnum.stringByAppendingString("}\n\n")
    }
    
    func createFileBody(variables: [(String, String, [String]?)]) -> String {
        
        var fileBody = "public class "
        fileBody = fileBody.stringByAppendingString(className)
        fileBody = fileBody.stringByAppendingString(": Mappable {\n\n")
        
        for i in 0..<variables.count {
            fileBody = fileBody.stringByAppendingString("    var ")
            fileBody = fileBody.stringByAppendingString(variables[i].0)
            fileBody = fileBody.stringByAppendingString(": ")
            
            if variables[i].2 != nil {
                fileBody = fileBody.stringByAppendingString(variables[i].0.setFirstLetterUppercase()) + "?\n"
            } else {
                fileBody = fileBody.stringByAppendingString(variables[i].1) + "?\n"
            }
        }

        fileBody = fileBody.stringByAppendingString("\n    init() {\n    }\n\n    required public init?(_ map: Map) {\n\n    }\n\n    public func mapping(map: Map) {\n")
        
        for tuple in variables {
            fileBody = fileBody.stringByAppendingString("        ")
            fileBody = fileBody.stringByAppendingString(tuple.0)
            fileBody = fileBody.stringByAppendingString(" <- map[\"")
            fileBody = fileBody.stringByAppendingString(tuple.0)
            fileBody = fileBody.stringByAppendingString("\"]\n")
        }

        fileBody = fileBody.stringByAppendingString("    }\n}\n")
        
        return fileBody
    }
    
    // MARK: - Helpers
    
    func getDesktopDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

extension String {
    func setFirstLetterUppercase() -> String {
        let firstCharacterRange = self.startIndex.advancedBy(0)..<self.startIndex.advancedBy(1)
        let enumNameFirstCharacter = self.substringWithRange(firstCharacterRange)
        var enumName = self
        enumName.replaceRange(firstCharacterRange, with: enumNameFirstCharacter.uppercaseString)
        return enumName
    }
}
