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
    
    func JSONCompatibleValueForAttribute(attributeName: String) -> AnyObject? {
        
        let attributeValue: AnyObject? = self.valueForKey(attributeName)
        
        return self.JSONCompatibleValueForAttributeValue(attributeValue!, forAttribute: attributeName)
    }
    
    func setJSONCompatibleValue(JSONCompatibleValue: AnyObject?, forAttribute attributeName: String) {
        
        let attributeValue: AnyObject? = self.attributeValueForJSONCompatibleValue(JSONCompatibleValue!, forAttribute: attributeName)
        
        self.setValue(attributeValue, forKey: attributeName)
    }
    
    func attributeValueForJSONCompatibleValue(JSONCompatibleValue: AnyObject, forAttribute attributeName: String) -> AnyObject? {
        
        return self.entity.attributeValueForJSONCompatibleValue(JSONCompatibleValue, forAttribute: attributeName)
    }
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String) -> AnyObject? {
        
        return self.entity.JSONCompatibleValueForAttributeValue(attributeValue, forAttribute: attributeName)
    }
    
    // MARK: - Validate
    
    func isValidConvertedValue(convertedValue: AnyObject, forAttribute attributeName: String) -> Bool {
        
        let attributeDescription = self.entity.attributesByName[attributeName] as? NSAttributeDescription
        
        if attributeDescription == nil {
            
            return false
        }
        
        let attributeType = attributeDescription?.attributeType
        
        // no JSON conversion for these values
        if attributeType == NSAttributeType.UndefinedAttributeType || attributeType == NSAttributeType.ObjectIDAttributeType {
                
            return false
        }
        
        // number types
        if attributeType == NSAttributeType.Integer16AttributeType || attributeType == NSAttributeType.Integer32AttributeType || attributeType == NSAttributeType.Integer64AttributeType || attributeType == NSAttributeType.DecimalAttributeType || attributeType == NSAttributeType.DoubleAttributeType || attributeType == NSAttributeType.FloatAttributeType || attributeType == NSAttributeType.BooleanAttributeType {
            
            // try to cast as number
            
            let number = convertedValue as? NSNumber
            
            return (number != nil)
        }
        
        // string type
        if attributeType == NSAttributeType.StringAttributeType {
            
            let string = convertedValue as? String
            
            return (string != nil)
        }
        
        // date type
        if attributeType == NSAttributeType.DateAttributeType {
            
            let date = convertedValue as? NSDate
            
            return (date != nil)
        }
        
        // data type
        if attributeType == NSAttributeType.BinaryDataAttributeType {
            
            let data = convertedValue as? NSData
            
            return (data != nil)
        }
        
        // transformable value type
        if attributeType == NSAttributeType.TransformableAttributeType {
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // anything that conforms to NSCoding
                return (convertedValue as? NSCoding != nil)
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            let data = transformer.transformedValue(convertedValue) as? NSData
            
            return (data != nil)
        }
        
        return false
    }
}

internal extension NSEntityDescription {
    
    // MARK: - Conversion Methods
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String) -> AnyObject? {
        
        let attributeDescription = self.attributesByName[attributeName] as? NSAttributeDescription
        
        if attributeDescription == nil {
            
            return nil
        }
        
        // give value based on attribute type...
        
        // if NSNull then just return NSNull     
        // nil attributes can be represented in JSON by NSNull
        if attributeValue as? NSNull != nil || attributeValue == nil {
            
            return NSNull()
        }
        
        let attributeClassName = attributeDescription!.attributeValueClassName
        
        // strings and numbers are standard json data types
        if attributeClassName == "NSString" || attributeClassName == "NSNumber" {
            
            return attributeValue
        }
        
        // date
        if attributeClassName == "NSDate" {
            
            
        }
        
        // transformable value type
        if attributeType == NSAttributeType.TransformableAttributeType {
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // anything that conforms
                return (convertedValue as? )
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            
        }
        
        return 0
    }
    
    func attributeValueForJSONCompatibleValue(JSONCompatibleValue: AnyObject, forAttribute attributeName: String) -> AnyObject? {
        
        
        // transformable value type
        if attributeType == NSAttributeType.TransformableAttributeType {
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // anything that conforms
                return (convertedValue as? )
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            
        }
    }
}

internal extension NSDate {
    
    
}

