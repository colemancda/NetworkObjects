//
//  CoreDataPredicateJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/2/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Extensions

// MARK: - Enumeration Extensions

public extension NSComparisonPredicateOptions {
    
    public init(searchComparisonPredicateOptions: [SearchComparisonPredicateOption]) {
        
        var rawOptionValue: UInt = NSComparisonPredicateOptions.allZeros.rawValue
        
        for option in searchComparisonPredicateOptions {
            
            let convertedOption = option.toComparisonPredicateOption()
            
            rawOptionValue = rawOptionValue | convertedOption.rawValue
        }
        
        self = NSComparisonPredicateOptions(rawValue: rawOptionValue)
    }
    
    public func toSearchComparisonPredicateOptions() -> [SearchComparisonPredicateOption]? {
        
        if self.rawValue == NSComparisonPredicateOptions.allZeros.rawValue {
            
            return nil
        }
        
        var searchComparisonPredicateOptions = [SearchComparisonPredicateOption]()
        
        let possibleValues: [UInt] = [NSComparisonPredicateOptions.CaseInsensitivePredicateOption.rawValue,
            NSComparisonPredicateOptions.DiacriticInsensitivePredicateOption.rawValue,
            NSComparisonPredicateOptions.NormalizedPredicateOption.rawValue,
            0x08 /* LocaleSensitive [l] */]
        
        for value in possibleValues {
            
            // check if raw value contains case
            if (self.rawValue & value) != 0 {
                
                let option: SearchComparisonPredicateOption = {
                    switch value {
                    case possibleValues[0]: return .CaseInsensitive
                    case possibleValues[1]: return .DiacriticInsensitive
                    case possibleValues[2]: return .Normalized
                    case possibleValues[3]: return .LocaleSensitive
                    default:
                        return SearchComparisonPredicateOption(rawValue: "")!
                    }
                    }()
                
                searchComparisonPredicateOptions.append(option)
            }
        }
        
        assert(searchComparisonPredicateOptions.count != 0, "NS_OPTION type NSComparisonPredicateOptions with raw value \(self.rawValue) could not be converted to SearchComparisonPredicateOption even though its rawValue was not zero")
        
        return searchComparisonPredicateOptions
    }
}

// MARK: - Internal Extensions

extension NSPredicate {
    
    func toJSON(#entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String : AnyObject] {
        
        NSException(name: NSInternalInconsistencyException, reason: "NSPredicate cannot be converted to JSON, only its subclasses", userInfo: nil).raise()
        
        return [String: AnyObject]()
    }
    
    convenience init?(JSONObject: [String: AnyObject]) {
        
        self.init(format: "")
        
        return nil
    }
}

extension NSComparisonPredicate {
    
    override func toJSON(#entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        if self.predicateOperatorType == NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            NSException(name: NSInternalInconsistencyException, reason: "Comparison Predicates with NSCustomSelectorPredicateOperatorType cannot be serialized to JSON for NetworkObjects Server/Store use", userInfo: nil).raise()
        }
        
        var jsonObject = [String: AnyObject]()
        
        // set primitive parameters
        jsonObject[SearchComparisonPredicateParameter.Operator.rawValue] = SearchComparisonPredicateOperator(predicateOperatorTypeValue: predicateOperatorType)!.rawValue
        jsonObject[SearchComparisonPredicateParameter.Modifier.rawValue] = SearchComparisonPredicateModifier(comparisonPredicateModifierValue: comparisonPredicateModifier).rawValue
        
        // array of options or nil
        jsonObject[SearchComparisonPredicateParameter.Options.rawValue] = {
           
            let searchOptions = self.options.toSearchComparisonPredicateOptions()
            
            if searchOptions == nil {
                
                return nil
            }
            
            var rawValues = [String]()
            
            for option in searchOptions! {
                
                rawValues.append(option.rawValue)
            }
            
            return rawValues
        }()
        
        // set key
        let key = leftExpression.keyPath
        jsonObject[SearchComparisonPredicateParameter.Key.rawValue] = key
        
        // set value
        jsonObject[SearchComparisonPredicateParameter.Value.rawValue] = entity.JSONObjectFromCoreDataValues([key: rightExpression.constantValue], usingResourceIDAttributeName: resourceIDAttributeName)
        
        return jsonObject
    }
    
}

extension NSCompoundPredicate {
    
    override func toJSON(#entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        var jsonObject = [String: AnyObject]()
        
        // compound type is string
        jsonObject[SearchCompoundPredicateParameter.PredicateType.rawValue] = SearchCompoundPredicateType(compoundPredicateTypeValue: self.compoundPredicateType).rawValue
        
        var subpredicateJSONArray = [[String: AnyObject]]()
        
        for predicate in self.subpredicates as [NSPredicate] {
            
            let predicateJSONObject = predicate.toJSON(entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
            
            subpredicateJSONArray.append(predicateJSONObject)
        }
        
        // set subpredicates
        jsonObject[SearchCompoundPredicateParameter.Subpredicates.rawValue] = subpredicateJSONArray
        
        return jsonObject
    }
}

// MARK: - Enumerations

/** The different types of predicates supported for search requests. */
public enum SearchPredicateType: String {
    
    /** The predicate is a comparison type (NSComparisonPredicate). */
    case Comparison = "Comparison"
    
    /** The predicate is a compound type (NSCompoundPredicate). */
    case Compound = "Compound"
}

// MARK: Comparison Predicate

/** The parameters for a comparison predicate. */
public enum SearchComparisonPredicateParameter: String {
    
    case Key = "Key"
    case Value = "Value"
    case Operator = "Operator"
    case Options = "Options"
    case Modifier = "Modifier"
}

public enum SearchComparisonPredicateOperator: String {
    
    case LessThan = "<"
    case LessThanOrEqualTo = "<="
    case GreaterThan = ">"
    case GreaterThanOrEqualTo = ">="
    case EqualTo = "="
    case NotEqualTo = "!="
    case Matches = "MATCHES"
    case Like = "LIKE"
    case BeginsWith = "BEGINSWITH"
    case EndsWith = "ENDSWITH"
    case In = "IN"
    case Contains = "CONTAINS"
    case Between = "BETWEEN"
    
    public init?(predicateOperatorTypeValue: NSPredicateOperatorType) {
        switch predicateOperatorTypeValue {
        case .LessThanPredicateOperatorType: self = .LessThan
        case .LessThanOrEqualToPredicateOperatorType: self = .LessThanOrEqualTo
        case .GreaterThanPredicateOperatorType: self = .GreaterThan
        case .GreaterThanOrEqualToPredicateOperatorType: self = .GreaterThanOrEqualTo
        case .EqualToPredicateOperatorType: self = .EqualTo
        case .NotEqualToPredicateOperatorType: self = .NotEqualTo
        case .MatchesPredicateOperatorType: self = .Matches
        case .LikePredicateOperatorType: self = .Like
        case .BeginsWithPredicateOperatorType: self = .BeginsWith
        case .EndsWithPredicateOperatorType: self = .EndsWith
        case .InPredicateOperatorType: self = .In
        case .ContainsPredicateOperatorType: self = .Contains
        case .BetweenPredicateOperatorType: self = .Between
        default: return nil
        }
    }
    
    public func toPredicateOperatorType() -> NSPredicateOperatorType {
        switch self {
        case .LessThan: return .LessThanPredicateOperatorType
        case .LessThanOrEqualTo: return .LessThanOrEqualToPredicateOperatorType
        case .GreaterThan: return .GreaterThanPredicateOperatorType
        case .GreaterThanOrEqualTo: return .GreaterThanOrEqualToPredicateOperatorType
        case .EqualTo: return .EqualToPredicateOperatorType
        case .NotEqualTo: return .NotEqualToPredicateOperatorType
        case .Matches: return .MatchesPredicateOperatorType
        case .Like: return .LikePredicateOperatorType
        case .BeginsWith: return .BeginsWithPredicateOperatorType
        case .EndsWith: return .EndsWithPredicateOperatorType
        case .In: return .InPredicateOperatorType
        case .Contains: return .ContainsPredicateOperatorType
        case .Between: return .BetweenPredicateOperatorType
        }
    }
}

public enum SearchComparisonPredicateOption: String {
    
    case CaseInsensitive = "[c]"
    case DiacriticInsensitive = "[d]"
    case Normalized = "[n]"
    case LocaleSensitive = "[l]"
    
    public func toComparisonPredicateOption() -> NSComparisonPredicateOptions {
        switch self {
        case .CaseInsensitive: return .CaseInsensitivePredicateOption
        case .DiacriticInsensitive: return .DiacriticInsensitivePredicateOption
        case .Normalized: return .NormalizedPredicateOption
        case .LocaleSensitive: return NSComparisonPredicateOptions(rawValue: 0x08)
        }
    }
}

public enum SearchComparisonPredicateModifier: String {
    
    case Direct = "DIRECT"
    case All = "ANY"
    case Any = "ALL"
    
    public init(comparisonPredicateModifierValue: NSComparisonPredicateModifier) {
        switch comparisonPredicateModifierValue {
        case .DirectPredicateModifier: self = .Direct
        case .AnyPredicateModifier: self = .Any
        case .AllPredicateModifier: self = .All
        }
    }
    
    public func toComparisonPredicateModifier() -> NSComparisonPredicateModifier {
        switch self {
        case .Direct: return .DirectPredicateModifier
        case .All: return .AllPredicateModifier
        case .Any: return .AnyPredicateModifier
        }
    }
}

// MARK: - Compound Predicate

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
