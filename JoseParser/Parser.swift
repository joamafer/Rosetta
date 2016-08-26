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

class Parser {
    var className : String!
    var variables : [(String, String, [String]?)] = []
    let projectName = "JoseParser"
    let creatorName = "Jose Fernandez"
    let companyName = "Locassa"
    
    func parse(text: String?) {
        
        let filePath = NSBundle.mainBundle().pathForResource("ModelToParse", ofType: "txt")!
        do {
            let fileContents: String!
            if text != nil {
                fileContents = text
            } else {
                fileContents = try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
            }
            
            let curlyBracketsCharacterSet = NSCharacterSet(charactersInString: "{}")
            let fileComponents = fileContents.componentsSeparatedByCharactersInSet(curlyBracketsCharacterSet).filter {$0 != ""}
            
            if fileComponents.count == 2 {
                self.className = fileComponents[0].stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
                
                let lines : [String] = fileComponents[1].componentsSeparatedByCharactersInSet(.newlineCharacterSet()).filter {$0 != ""}
                
                for line in lines {
                    if let tuple = self.parseLine(line.stringByReplacingOccurrencesOfString(" ", withString: "")) {
                        variables.append(tuple)
                    }
                }
                
                self.createFile(variables)
                
            } else {
                print("Error: The format of the model is not correct")
            }
            
        } catch {
            print("Error: Cannot find file")
        }
    }
    
    func parseLine(line : String) -> (String, String, [String]?)? {
        
        let customCharacterSet = NSCharacterSet(charactersInString: "(,")
        let lineComponents = line.componentsSeparatedByCharactersInSet(customCharacterSet).filter{ $0 != ""}
        
        if lineComponents.count > 2 {
            
            var variableName = lineComponents[0]
            let variableType = VariableTypes.convertVariableType(lineComponents[1])
            var enumValues : [String]?
            
            if lineComponents.count > 3 { // enum
                
                variableName = variableName.capitalizedString
                
                let customCharacterSet = NSCharacterSet(charactersInString: "[]")
                let enumComponents = line.componentsSeparatedByCharactersInSet(customCharacterSet).filter{ $0 != ""}
                
                if enumComponents.count == 3 {
                    enumValues = self.parseEnum(enumComponents[1])
                }
            }
            
            return (variableName, variableType, enumValues)
            
        } else {
            print("Error: Cannot parse line")
            
            return nil
        }
    }
    
    func parseEnum(lineWithEnum : String) -> [String] {
        let squareBracketsCharacterSet = NSCharacterSet(charactersInString: ",")
        return lineWithEnum.componentsSeparatedByCharactersInSet(squareBracketsCharacterSet).filter{ $0 != "," && $0 != "" }
    }
    
    // MARK: - File creation
    
    func createFile(variables: [(String, String, [String]?)]) {
        var finalFile = self.createFileInfo()
        
        let enumTuples = variables.filter( { $2 != nil } )
        for enumTuple in enumTuples {
            finalFile = finalFile.stringByAppendingString(self.createFileEnum((enumTuple.0, enumTuple.1, enumTuple.2!)))
        }
        
        finalFile = finalFile.stringByAppendingString(self.createFileBody(variables))
        
        let filename = getDesktopDirectory().stringByAppendingPathComponent(className + ".swift")
        
        do {
            try finalFile.writeToFile(filename, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            print("Error: bad permissions, bad filename, missing permissions or the encoding failed")
        }
    }
    
    func createFileInfo() -> String {
        var fileInfo = "//\n//  " + className + ".swift\n//  "
        fileInfo = fileInfo.stringByAppendingString(projectName) + "\n//\n//  Created by "
        fileInfo = fileInfo.stringByAppendingString(creatorName) + " on "
        let date = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .NoStyle)
        fileInfo = fileInfo.stringByAppendingString(date)
        fileInfo = fileInfo.stringByAppendingString("\n//  Copyright © ")
        fileInfo = fileInfo.stringByAppendingString(date[date.startIndex.advancedBy(6)..<date.startIndex.advancedBy(10)]) + " "
        fileInfo = fileInfo.stringByAppendingString(companyName)
        fileInfo = fileInfo.stringByAppendingString(". All rights reserved.\n//\n\n")
        fileInfo = fileInfo.stringByAppendingString("import ObjectMapper\n\n")
        
        return fileInfo
    }
    
    func createFileEnum(tuple: (enumName : String, enumType : String, enumValues : [String])) -> String {
        var fileEnum = ("enum ")
        fileEnum = fileEnum.stringByAppendingString(tuple.enumName)
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
            fileBody = fileBody.stringByAppendingString(variables[i].1) + "?\n"
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
