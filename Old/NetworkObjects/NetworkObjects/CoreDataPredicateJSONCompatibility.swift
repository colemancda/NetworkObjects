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

internal extension NSPredicate {
    
    /// Creates a contrete subclass of NSPredicate from the provided JSON.
    ///
    /// - parameter JSONObject: The JSON dictionary used to create the predicate
    /// - returns: A concrete subclass of NSPredicate or nil if the provided JSON was incorrect
    class func predicateWithJSON(JSONObject: [String: AnyObject], entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) throws -> NSPredicate? {
        
        guard JSONObject.count == 1,
            let predicateType = SearchPredicateType(rawValue: JSONObject.keys.first!),
            let predicateJSONObject = JSONObject.values.first as? [String: AnyObject]
            else { return nil }
        
        // create concrete subclass from values
        switch predicateType {
            
        case .Comparison: return try NSComparisonPredicate(JSONObject: predicateJSONObject, entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
            
        case .Compound: return try NSCompoundPredicate(JSONObject: predicateJSONObject, entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
        }
    }
    
    func toJSON(entity entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String : AnyObject] {
        
        NSException(name: NSInternalInconsistencyException, reason: "NSPredicate cannot be converted to JSON, only its concrete subclasses", userInfo: nil).raise()
        
        return [String: AnyObject]()
    }
}

internal extension NSComparisonPredicate {
    
    convenience init?(JSONObject: [String: AnyObject], entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) throws {
        
        guard let predicateOperatorString = JSONObject[SearchComparisonPredicateParameter.Operator.rawValue] as? String,
            let predicateOperatorType =  SearchComparisonPredicateOperator(rawValue: predicateOperatorString)?.toPredicateOperatorType() else {
            
            return nil
        }
        
        guard let modifier: NSComparisonPredicateModifier? = {
            
            guard let modifierString = JSONObject[SearchComparisonPredicateParameter.Modifier.rawValue] as? String else {
                
                // default
                return NSComparisonPredicateModifier.DirectPredicateModifier
            }
            
            guard let modifier = SearchComparisonPredicateModifier(rawValue: modifierString)?.toComparisonPredicateModifier() else {
                
                return nil
            }
            
            return modifier
        }()
        else { return nil }
        
        guard let options: NSComparisonPredicateOptions? = {
            
            guard let optionsObject = JSONObject[SearchComparisonPredicateParameter.Options.rawValue] else {
                
                // default
                return NSComparisonPredicateOptions()
            }
            
            guard let optionsArray = optionsObject as? [String],
                let searchComparisonOptions = SearchComparisonPredicateOption.fromRawValues(optionsArray) else {
                    
                return nil
            }
            
            // Compiler error in Xcode 6.3
            //return NSComparisonPredicateOptions(searchComparisonPredicateOptions: searchComparisonOptions!)
            
            return SearchComparisonPredicateOptionsToNSComparisonPredicateOptions(searchComparisonOptions)
        }()
        else { return nil }
        
        // set left expression
        guard let leftExpression: NSExpression? = {
            
            guard let key = JSONObject[SearchComparisonPredicateParameter.Key.rawValue] as? String else {
                
                return nil
            }
            
            let attribute = entity.attributesByName[key]
            
            let relationship = entity.relationshipsByName[key]
            
            if attribute == nil && relationship == nil {
                
                return nil
            }
            
            return NSExpression(forKeyPath: key)
            }()
        else { return nil }
        
        // set right expression
        guard let rightExpression: NSExpression? = try {
            
            let jsonPredicateValue: AnyObject? = JSONObject[SearchComparisonPredicateParameter.Value.rawValue]
            
            if jsonPredicateValue == nil {
                
                return nil
            }
            
            if (jsonPredicateValue as? NSNull) != nil {
                
                return NSExpression(forConstantValue: NSNull())
            }
            
            // convert
            let convertedValue: AnyObject? = try {
                
                let key = leftExpression!.keyPath
                
                let attribute = entity.attributesByName[key]
                
                let relationship = entity.relationshipsByName[key]
                
                if attribute == nil && relationship == nil {
                    
                    return nil
                }
                
                // attribute
                if attribute != nil {
                    
                    let (newValue, _) = entity.attributeValueForJSONCompatibleValue(jsonPredicateValue!, forAttribute: key)
                    
                    return newValue
                }
                
                // relationship...
                
                let model = managedObjectContext.persistentStoreCoordinator!.managedObjectModel
                
                // to-one
                if !relationship!.toMany {
                    
                    let resourceDictionary = jsonPredicateValue as? [String: UInt]
                    
                    // verify
                    if resourceDictionary == nil || resourceDictionary?.count != 1  {
                        
                        return nil
                    }
                    
                    let resourceID = resourceDictionary!.values.first!
                    
                    let resourceEntityName = resourceDictionary!.keys.first!
                    
                    let resourceEntity = model.entitiesByName[resourceEntityName]
                    
                    // verify
                    if resourceEntity == nil || !(resourceEntity?.isKindOfEntity(relationship!.destinationEntity!) ?? true) {
                        
                        return nil
                    }
                    
                    let fetchedResource = try FetchEntity(resourceEntity!, withResourceID: resourceID, usingContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName, shouldPrefetch: false)
                    
                    // not found
                    if fetchedResource == nil {
                        
                        return nil
                    }
                    
                    // set value
                    return fetchedResource!
                }
                    
                // to-many relationships
                else {
                    
                    let resourceDictionaries = jsonPredicateValue as? [[String: UInt]]
                    
                    // verify
                    if resourceDictionaries == nil {
                        
                        return nil
                    }
                    
                    var fetchedManagedObjects = [NSManagedObject]()
                    
                    for resourceDictionary in resourceDictionaries! {
                        
                        // verify
                        if resourceDictionary.count != 1  {
                            
                            return nil
                        }
                        
                        let resourceID = resourceDictionary.values.first!
                        
                        let resourceEntityName = resourceDictionary.keys.first!
                        
                        let resourceEntity = model.entitiesByName[resourceEntityName]
                        
                        // verify
                        if resourceEntity == nil || !(resourceEntity?.isKindOfEntity(relationship!.destinationEntity!) ?? true)  {
                            
                            return nil
                        }
                        
                        let fetchedResource = try FetchEntity(resourceEntity!, withResourceID: resourceID, usingContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName, shouldPrefetch: false)
                        
                        // not found
                        if fetchedResource == nil {
                            
                            return nil
                        }
                        
                        fetchedManagedObjects.append(fetchedResource!)
                    }
                    
                    // set value
                    return fetchedManagedObjects
                }
                
            }()
            
            if convertedValue == nil {
                
                return nil
            }
            
            return NSExpression(forConstantValue: convertedValue!)
        }()
        
        else { return nil }
        
        // initialize with values
        self.init(leftExpression: leftExpression!, rightExpression: rightExpression!, modifier: modifier!, type: predicateOperatorType, options: options!)
    }
    
    override func toJSON(entity entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        if self.predicateOperatorType == NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            NSException(name: NSInternalInconsistencyException, reason: "Comparison Predicates with NSCustomSelectorPredicateOperatorType cannot be serialized to JSON", userInfo: nil).raise()
        }
        
        var jsonObject = [String: AnyObject]()
        
        // set primitive parameters
        jsonObject[SearchComparisonPredicateParameter.Operator.rawValue] = SearchComparisonPredicateOperator(predicateOperatorTypeValue: predicateOperatorType)!.rawValue
        jsonObject[SearchComparisonPredicateParameter.Modifier.rawValue] = SearchComparisonPredicateModifier(comparisonPredicateModifierValue: comparisonPredicateModifier).rawValue
        
        // array of options or nil
        if let predicateOptions = options.toSearchComparisonPredicateOptions() {
            
            jsonObject[SearchComparisonPredicateParameter.Options.rawValue] = predicateOptions.rawValues
        }
        
        // set key
        let key = leftExpression.keyPath
        jsonObject[SearchComparisonPredicateParameter.Key.rawValue] = key
        
        // set value
        jsonObject[SearchComparisonPredicateParameter.Value.rawValue] = entity.JSONObjectFromCoreDataValues([key: rightExpression.constantValue], usingResourceIDAttributeName: resourceIDAttributeName).values.first!
        
        return [SearchPredicateType.Comparison.rawValue: jsonObject]
    }
    
}

internal extension NSCompoundPredicate {
    
    convenience init?(JSONObject: [String: AnyObject], entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) throws {
        
        // get the type
        guard let compoundPredicateType: NSCompoundPredicateType? = {
           
            let predicateTypeString = JSONObject[SearchCompoundPredicateParameter.PredicateType.rawValue] as? String
            
            if predicateTypeString == nil {
                
                return nil
            }
            
            let predicateType = SearchCompoundPredicateType(rawValue: predicateTypeString!)
            
            return predicateType?.toCompoundPredicateType()
        }() else { return nil }
        
        // get the subpredicates
        guard let subpredicates: [NSPredicate]? = try {
            
            let subpredicatesJSONArray = JSONObject[SearchCompoundPredicateParameter.Subpredicates.rawValue] as? [[String: AnyObject]]
            
            if subpredicatesJSONArray == nil {
                
                return nil
            }
            
            var predicates = [NSPredicate]()
            
            for predicateJSONObject in subpredicatesJSONArray! {
                
                guard let predicate: NSPredicate? = try NSPredicate.predicateWithJSON(predicateJSONObject, entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName) else {
                    
                    return nil
                }
                
                predicates.append(predicate!)
            }
            
            return predicates
        }() else { return nil }
        
        self.init(type: compoundPredicateType!, subpredicates: subpredicates!)
    }
    
    override func toJSON(entity entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        var jsonObject = [String: AnyObject]()
        
        // compound type is string
        jsonObject[SearchCompoundPredicateParameter.PredicateType.rawValue] = SearchCompoundPredicateType(compoundPredicateTypeValue: self.compoundPredicateType).rawValue
        
        var subpredicateJSONArray = [[String: AnyObject]]()
        
        for predicate in self.subpredicates as! [NSPredicate] {
            
            let predicateJSONObject = predicate.toJSON(entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
            
            subpredicateJSONArray.append(predicateJSONObject)
        }
        
        // set subpredicates
        jsonObject[SearchCompoundPredicateParameter.Subpredicates.rawValue] = subpredicateJSONArray
        
        return [SearchPredicateType.Compound.rawValue: jsonObject]
    }
}

// MARK: - Enumeration Extensions

public func SearchComparisonPredicateOptionsToNSComparisonPredicateOptions(searchComparisonPredicateOptions: [SearchComparisonPredicateOption]) -> NSComparisonPredicateOptions {
    
    var rawOptionValue: UInt = 0
    
    for option in searchComparisonPredicateOptions {
        
        let convertedOption = option.toComparisonPredicateOption()
        
        rawOptionValue = rawOptionValue | convertedOption.rawValue
    }
    
    return NSComparisonPredicateOptions(rawValue: rawOptionValue)
}

public extension NSComparisonPredicateOptions {
    
    /* Compiler error in Xcode 6.3
    public init(searchComparisonPredicateOptions: [SearchComparisonPredicateOption]) {
        
        var rawOptionValue: UInt = 0
        
        for option in searchComparisonPredicateOptions {
            
            let convertedOption = option.toComparisonPredicateOption()
            
            rawOptionValue = rawOptionValue | convertedOption.rawValue
        }
        
        self = NSComparisonPredicateOptions(rawValue: rawOptionValue)
    }
    */
    
    public func toSearchComparisonPredicateOptions() -> [SearchComparisonPredicateOption]? {
        
        if self.rawValue == NSComparisonPredicateOptions().rawValue {
            
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
