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

extension NSPredicate {
    
    func toJSON(managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String : AnyObject] {
        
        NSException(name: NSInternalInconsistencyException, reason: "NSPredicate cannot be converted to JSON, only its subclasses", userInfo: nil).raise()
        
        return [String: AnyObject]()
    }
    
    convenience init?(JSONObject: [String: AnyObject]) {
        
        self.init(format: "")
        
        return nil
    }
}

extension NSComparisonPredicate {
    
    override func toJSON(managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        if self.predicateOperatorType == NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            NSException(name: NSInternalInconsistencyException, reason: "Comparison Predicates with NSCustomSelectorPredicateOperatorType cannot be serialized to JSON for NetworkObjects Server/Store use", userInfo: nil).raise()
        }
        
        var jsonObject = [String: AnyObject]()
        
        // set primitive parameters
        jsonObject[SearchComparisonPredicateParameter.Operator.rawValue] = predicateOperatorType.rawValue
        jsonObject[SearchComparisonPredicateParameter.Option.rawValue] = options.rawValue
        jsonObject[SearchComparisonPredicateParameter.Modifier.rawValue] = comparisonPredicateModifier.rawValue
        
        // set expressions
        jsonObject[SearchComparisonPredicateParameter.LeftExpression.rawValue] = leftExpression.toJSON(managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
        jsonObject[SearchComparisonPredicateParameter.RightExpression.rawValue] = rightExpression.toJSON(managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
        
        return jsonObject
    }
    
}

extension NSCompoundPredicate {
    
    override func toJSON(managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        var jsonObject = [String: AnyObject]()
        
        // compound type is string
        jsonObject[SearchCompoundPredicateParameter.PredicateType.rawValue] = SearchCompoundPredicateType(compoundPredicateTypeValue: self.compoundPredicateType).rawValue
        
        var subpredicateJSONArray = [[String: AnyObject]]()
        
        for predicate in self.subpredicates as [NSPredicate] {
            
            let predicateJSONObject = predicate.toJSON(managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
            
            subpredicateJSONArray.append(predicateJSONObject)
        }
        
        // set subpredicates
        jsonObject[SearchCompoundPredicateParameter.Subpredicates.rawValue] = subpredicateJSONArray
        
        return jsonObject
    }
}

extension NSExpression {
    
    func toJSON(managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String : AnyObject] {
        
        
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
    
    case LeftExpression = "LeftExpression"
    case RightExpression = "RightExpression"
    case Operator = "Operator"
    case Option = "Option"
    case Modifier = "Modifier"
}

/** The parameters for a compound predicate. */
public enum SearchCompoundPredicateParameter: String {
    
    case PredicateType = "PredicateType"
    case Subpredicates = "Subpredicates"
}

/** Type of compound predicate. */
public enum SearchCompoundPredicateType: String {
    
    case Not = "Not"
    case And = "And"
    case Or = "Or"
    
    public init(compoundPredicateTypeValue: NSCompoundPredicateType) {
        switch compoundPredicateTypeValue {
        case .NotPredicateType: self = .Not
        case .AndPredicateType: self = .And
        case .OrPredicateType: self = .Or
        }
    }
    
    public func toCompoundPredicateType() -> NSCompoundPredicateType {
        switch self {
        case .Not: return .NotPredicateType
        case .And: return .AndPredicateType
        case .Or: return .OrPredicateType
        }
    }
}

/** The parameters for a search expression. */
public enum SearchExpressionParameter: String {
    
    case ExpressionType = "ExpressionType"
    case Value = "Value"
}

/** Search expression type. */
public enum SearchExpressionType: String {
    
    case ConstantValue = "ConstantValue"
    case AnyKey = "AnyKey"
    case Key = "Key"
    
    public func toExpressionType() -> NSExpressionType {
        switch self {
        case .ConstantValue: return .ConstantValueExpressionType
        case .AnyKey: return .AnyKeyExpressionType
        case .Key: return .KeyPathExpressionType
        }
    }
    
    public init?(expressionTypeValue: NSExpressionType) {
        
        switch expressionTypeValue {
            
        case .ConstantValueExpressionType: self = .ConstantValue
        case .AnyKeyExpressionType: self = .AnyKey
        case .KeyPathExpressionType: self = .Key
            
        default: return nil
        }
    }
}
