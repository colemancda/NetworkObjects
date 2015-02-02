//
//  CoreDataPredicateJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/2/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Internal Extensions

internal extension NSComparisonPredicate {
    
    func toJSON(managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject]? {
        
        if self.predicateOperatorType == NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            NSException(name: NSInternalInconsistencyException, reason: "Comparison Predicates with NSCustomSelectorPredicateOperatorType cannot be serialized to JSON for NetworkObjects Server/Store use", userInfo: nil).raise()
        }
        
        var jsonObject = [String: AnyObject]()
        
        // set keyPath
        jsonObject[SearchComparisonPredicateParameter.Key.rawValue] = self.leftExpression.keyPath
        
        
        
        // convert from Core Data to JSON
        let jsonValue: AnyObject? = fetchRequest.entity!.JSONObjectFromCoreDataValues([predicate!.leftExpression.keyPath: predicate!.rightExpression.constantValue], usingResourceIDAttributeName: resourceIDAttributeName).values.first
        
        jsonObject[SearchComparisonPredicateParameter.Value.rawValue] = jsonValue
        
        jsonObject[SearchComparisonPredicateParameter.Operator.rawValue] = predicate?.predicateOperatorType.rawValue
        
        jsonObject[SearchComparisonPredicateParameter.Option.rawValue] = predicate?.options.rawValue
        
        jsonObject[SearchComparisonPredicateParameter.Modifier.rawValue] = predicate?.comparisonPredicateModifier.rawValue
    }
}

// MARK: - Enumerations

/** The different types of predicates supported for search requests. */
public enum SearchPredicateType: String {
    
    /** The predicate is a comparison type (NSComaprisonPredicate). */
    case Comparison = "Comparison"
    
    /** The predicate is a compound type (NSCompoundPredicate). */
    case Compound = "Compound"
}

/** The parameters for a comparison predicate. */
public enum SearchComparisonPredicateParameter: String {
    
    case Key = "Key"
    case Value = "Value"
    case Operator = "Operator"
    case Option = "Option"
    case Modifier = "Modifier"
}