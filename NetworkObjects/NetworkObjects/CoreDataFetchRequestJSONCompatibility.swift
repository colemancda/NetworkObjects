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
    
    /// Initializes from a JSON dictionary, fails for invalid JSON or invalid key.
    ///
    /// :param: JSONObject JSON dictionary with a single key and a boolean value
    /// :param: entity The entity to use to validate the key
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
    
    /// Converts to JSON.
    ///
    /// :returns: JSON dictionary with a single key and the ascending value.
    func toJSON() -> [String: Bool] {
        
        assert(self.key != nil, "")
        
        return [self.key!: ascending]
    }
}

// MARK: - Enumerations

/** Defines the keys of the search request's JSON body. */
public enum SearchParameter: String {
    
    /** A JSON object representing the search predicate. Optional. */
    case Predicate = "Predicate"
    
    /** The search request's fetch limit. Value for this key will be a UInt. Optional. */
    case FetchLimit = "FetchLimit"
    
    /** The offset for the search request. Value for this key will be a UInt. Optional. */
    case FetchOffset = "FetchOffset"

    /** Whether the search request should include subentities. Value for this key will be a Bool. Defaults to false. Optional. */
    case IncludesSubentities = "IncludesSubentities"
    
    /** The descriptors the search request should use to sort the results. Value for this key will an array of JSON dictionaries representing sort descriptors. Optional. */
    case SortDescriptors = "SortDescriptors"
}

