//
//  CoreDataFetchRequestJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/3/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

internal extension NSFetchRequest {
    
    func toJSON(managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        
    }
}

internal extension NSSortDescriptor {
    
    convenience init?(JSONObject: [String: Bool], entity: NSEntityDescription) {
        
        // validate JSON
        if JSONObject.count != 1 {
            
            self.init(key:  "", ascending: true)
            return nil
        }
        
        let key = JSONObject.keys.first!
        
        let value = JSONObject.values.first!
        
        // validate key
        let property = entity.propertiesByName[key] as? NSPropertyDescription
        
        if property == nil {
            
            self.init(key:  "", ascending: true)
            return nil
        }
        
        self.init(key: key, ascending: value)
    }
    
    func toJSON() -> [String: Bool] {
        
        return [self.key!: ascending]
    }
}

// MARK: - Enumerations

public enum SearchSortDescriptorParameter: String {
    
    case Key = "Key"
    case Ascending = "Ascending"
}