//
//  CoreDataConvenienceExtensions.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/5/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

internal extension NSManagedObject {
        
    /** Get an array from a to-many relationship. */
    func arrayValueForToManyRelationship(relationship key: String) -> [NSManagedObject]? {
        
        // assert relationship exists
        assert(self.entity.relationshipsByName[key] as? NSRelationshipDescription != nil, "Relationship \(key) doesnt exist on \(self.entity.name)")
        
        // get relationship
        let relationship = self.entity.relationshipsByName[key] as! NSRelationshipDescription
        
        // assert that relationship is to-many
        assert(relationship.toMany, "Relationship \(key) on \(self.entity.name) is not to-many")
        
        let value: AnyObject? = self.valueForKey(key)
        
        if value == nil {
            
            return nil
        }
        
        // ordered set
        if relationship.ordered {
            
            let orderedSet = value as! NSOrderedSet
            
            return orderedSet.array as? [NSManagedObject]
        }
        
        // set
        let set = value as! NSSet
        
        return set.allObjects as? [NSManagedObject]
    }
    
    /** Wraps the -valueForKey: method in the context's queue. */
    func valueForKey(key: String, managedObjectContext: NSManagedObjectContext) -> AnyObject? {
        
        var value: AnyObject?
        
        managedObjectContext.performBlockAndWait { () -> Void in
            
            value = self.valueForKey(key)
        }
        
        return value
    }
}

internal extension NSPredicate {
    
    /** Transverses the predicate tree and returns all comparison predicates. If this is called on an instance of NSComparisonPredicate, then an array with self is returned. Only use with concrete subclasses of NSPredicate. */
    func extractComparisonSubpredicates() -> [NSComparisonPredicate] {
        
        assert(self.dynamicType !== NSPredicate.self, "Cannot extract comparison subpredicates from NSPredicate, must use concrete subclasses")
        
        // main predicate is comparison predicate
        if let comparisonPredicate = self as? NSComparisonPredicate {
            
            return [comparisonPredicate]
        }
        
        let compoundPredicate = self as! NSCompoundPredicate
        
        let comparisonPredicates = NSMutableArray()
        
        for subpredicate in compoundPredicate.subpredicates as! [NSPredicate] {
            
            let subpredicates = subpredicate.extractComparisonSubpredicates()
            
            comparisonPredicates.addObjectsFromArray(subpredicates)
        }
        
        return (comparisonPredicates as NSArray) as! [NSComparisonPredicate]
    }
}