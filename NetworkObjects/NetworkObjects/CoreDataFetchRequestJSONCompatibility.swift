//
//  CoreDataFetchRequestJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/3/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Internal Extensions

internal extension NSFetchRequest {
    
    /** Creates a fetch request from a JSON object. */
    convenience init?(JSONObject: [String: AnyObject], entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String, error: NSErrorPointer) {
        
        self.init()
        
        self.entity = entity
        
        // set sort descriptors....
        if let sortDescriptorsObject: AnyObject = JSONObject[SearchParameter.SortDescriptors.rawValue] {
            
            let sortDescriptorsJSONArray = sortDescriptorsObject as? [[String: Bool]]
            
            if sortDescriptorsJSONArray == nil {
                
                return nil
            }
            
            var sortDescriptors = [NSSortDescriptor]()
            
            for sortDescriptorJSONObject in sortDescriptorsJSONArray! {
                
                let sortDescriptor = NSSortDescriptor(JSONObject: sortDescriptorJSONObject, entity: entity)
                
                if sortDescriptor == nil {
                    
                    return nil
                }
                
                sortDescriptors.append(sortDescriptor!)
            }
            
            self.sortDescriptors = sortDescriptors
        }
            
        // default sort descriptor
        else {
            
            self.sortDescriptors = [NSSortDescriptor(key: resourceIDAttributeName, ascending: false)]
        }
        
        // set the fetch limit
        if let fetchLimitObject: AnyObject = JSONObject[SearchParameter.FetchLimit.rawValue] {
            
            let fetchLimit = fetchLimitObject as? UInt
            
            if fetchLimit == nil {
                
                return nil
            }
            
            self.fetchLimit = Int(fetchLimit!)
        }
        
        // set the fetch offset
        if let fetchOffsetObject: AnyObject = JSONObject[SearchParameter.FetchOffset.rawValue] {
            
            let fetchOffset = fetchOffsetObject as? UInt
            
            if fetchOffset == nil {
                
                return nil
            }
            
            self.fetchOffset = Int(fetchOffset!)
        }
        
        // set includesSubentities
        if let includesSubentitiesObject: AnyObject = JSONObject[SearchParameter.IncludesSubentities.rawValue] {
            
            let includesSubentities = includesSubentitiesObject as? Bool
            
            if includesSubentities == nil {
                
                return nil
            }
            
            self.includesSubentities = includesSubentities!
        }
        
        // set predicate
        if let predicateObject: AnyObject = JSONObject[SearchParameter.Predicate.rawValue] {
            
            let predicateJSONObject = predicateObject as? [String: AnyObject]
            
            if predicateJSONObject == nil {
                
                return nil
            }
            
            let predicate = NSPredicate.predicateWithJSON(predicateJSONObject!, entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName, error: error)
            
            if predicate == nil {
                
                return nil
            }
            
            self.predicate = predicate
        }
    }
    
    /// Serializes a fetch request to JSON. See SearchParameter for the keys of the generated JSON dictionary.
    /// The fetch request's predicate must be a concrete subclass of NSPredicate. NSComparisonPredcate instances must specify a key on the left expression and a attribute or relationship value on the right expression.
    ///
    /// :param: managedObjectContext Used for retrieved the resourceID of managed objects referenced in predicates.
    /// :param: resourceIDAttributeName Key for retreiving the resourceID of referenced managed objects.
    /// :returns: JSON object representing the fetch request. Will raise an exception if the fetch request cannot be serialized due to invalid values.
    func toJSON(managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        // get the entity of the fetch request
        
        let entity: NSEntityDescription
        
        if let entityName = self.entityName {
            
            assert(managedObjectContext.persistentStoreCoordinator != nil, "Managed Object Context must have a Persistent Store Coordinator for fetch requests created with strings")
            
            entity = managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[entityName] as! NSEntityDescription
        }
        else {
            
            entity = self.entity!
        }
        
        // create JSON object
        var jsonObject = [String: AnyObject]()
        
        // set the sort descriptors...
        if let sortDescriptors = self.sortDescriptors as? [NSSortDescriptor] {
            
            var sortDescriptorsJSONArray = [[String: Bool]]()
            
            for sortDescriptor in sortDescriptors {
                
                sortDescriptorsJSONArray.append(sortDescriptor.toJSON())
            }
            
            // add to JSON object
            jsonObject[SearchParameter.SortDescriptors.rawValue] = sortDescriptorsJSONArray
        }
        
        // set the fetch limit
        if self.fetchLimit > 0 {
            
            jsonObject[SearchParameter.FetchLimit.rawValue] = self.fetchLimit
        }
        
        // set fetch offset
        if self.fetchOffset > 0 {
            
            jsonObject[SearchParameter.FetchOffset.rawValue] = self.fetchOffset
        }
        
        // set includesSubentities (only add if false, default is true)
        if !self.includesSubentities {
            
            jsonObject[SearchParameter.IncludesSubentities.rawValue] = self.includesSubentities
        }
        
        // set predicate
        if self.predicate != nil {
            
            let predicateJSONObject = self.predicate!.toJSON(entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
            
            jsonObject[SearchParameter.Predicate.rawValue] = predicateJSONObject
        }
        
        return jsonObject
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
            
            self.init()
            return nil
        }
        
        let key = JSONObject.keys.first!
        let value = JSONObject.values.first!
        
        // validate key
        let attribute = entity.attributesByName[key] as? NSAttributeDescription
        let relationship = entity.relationshipsByName[key] as? NSRelationshipDescription
        
        if attribute == nil && relationship == nil {
            
            self.init()
            return nil
        }
        
        self.init(key: key, ascending: value)
    }
    
    /// Converts to JSON.
    ///
    /// :returns: JSON dictionary with a single key and the ascending value.
    func toJSON() -> [String: Bool] {
        
        assert(self.key != nil, "Key must be specified for sort descriptor")
        
        return [self.key!: ascending]
    }
}

// MARK: - Enumerations

/** Defines the parameters for search requests. Also used as keys for for converting a NSFetchRequest to JSON. All keys are optional. */
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

