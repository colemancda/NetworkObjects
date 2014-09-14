//
//  CoreDataJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

internal extension NSManagedObject {
    
    // MARK: - Convenience Methods
    
    func JSONCompatibleValueForAttribute(attributeName: String) -> AnyObject {
        
        let attributeValue: AnyObject? = self.valueForKey(attributeName)
        
        return self.JSONCompatibleValueForAttributeValue(attributeValue!, forAttribute: attributeName)
    }
    
    func setJSONCompatibleValue(JSONCompatibleValue: AnyObject, forAttribute attributeName: String) {
        
        let attributeValue: AnyObject = self.attributeValueForJSONCompatibleValue(JSONCompatibleValue, forAttribute: attributeName)
        
        self.setValue(attributeValue, forKey: attributeName)
    }
    
    func attributeValueForJSONCompatibleValue(JSONCompatibleValue: AnyObject, forAttribute attributeName: String) -> AnyObject {
        
        return self.entity.attributeValueForJSONCompatibleValue(JSONCompatibleValue, forAttribute: attributeName)
    }
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject, forAttribute attributeName: String) -> AnyObject {
        
        return self.entity.JSONCompatibleValueForAttributeValue(attributeValue, forAttribute: attributeName)
    }
    
    // MARK: - Validate
    
    func isValidConvertedValue(value: AnyObject, forAttribute attributeName: String) -> Bool {
        
        
        
        return false
    }
}

internal extension NSEntityDescription {
    
    // MARK: - Conversion Methods
    
    func attributeValueForJSONCompatibleValue(JSONCompatibleValue: AnyObject, forAttribute attributeName: String) -> AnyObject {
        
        
    }
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject, forAttribute attributeName: String) -> AnyObject {
        
        return 0
    }
}