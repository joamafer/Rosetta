//
//  PreferencesConfiguration.swift
//  JoseParser
//
//  Created by JOSE ANTONIO MARTINEZ FERNANDEZ on 20/11/2016.
//  Copyright © 2016 joamafer. All rights reserved.
//

import AppKit

enum MappingMode: String {
    case manual = "Manual", objectmapper = "ObjectMapper", swiftyJSON = "SwiftyJSON (coming soon)", freddy = "Freddy (coming soon)", gloss = "Gloss (coming soon)"
    
    static let allValues = [manual, objectmapper, swiftyJSON, freddy, gloss].map{ $0.rawValue }
}

enum PreferencesKeys: String {
    case addCommentsHeader, indentationSpaces, mappingMode, author, projectName, companyName
    
    static func get<T>(setting key: PreferencesKeys) -> T? {
        return UserDefaults.standard.value(forKey: key.rawValue) as? T
    }
    
    static func set<T>(setting key: PreferencesKeys, value: T) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}

extension Notification.Name {
    static let preferencesUpdated = Notification.Name("preferencesUpdated")
}
