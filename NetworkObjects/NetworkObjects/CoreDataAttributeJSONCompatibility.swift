//
//  CoreDataAttributeJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

/** Static options for CoreData <-> JSON conversion. */
struct CoreDataAttributeJSONCompatibilityOptions {
    static var Base64EncodingOptions = NSDataBase64EncodingOptions.allZeros
    static var Base64DecodingOptions = NSDataBase64DecodingOptions.allZeros
}

internal extension NSEntityDescription {
    
    // MARK: - Conversion Methods
    
    /// Converts a Core Data attribute value to a JSON-compatible value.
    /// 
    /// :param: attributeValue The Core Data compatible value that will be converted to JSON. Accepts NSNull as a convenience is case this is called using the values of a dictionary, which cannot hold nil. 
    /// :param: attributeName The name the of attribute that will be used to convert the value. Must be a valid attribute.
    /// :returns: The converted JSON value.
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String) -> AnyObject {
        
        let attributeDescription = self.attributesByName[attributeName] as? NSAttributeDescription
        
        assert(attributeDescription != nil, "Attribute named \(attributeName) not found on entity \(self)")
        
        // give value based on attribute type...
        
        // if NSNull then just return NSNull
        // nil attributes can be represented in JSON by NSNull
        // Accepts NSNull as a convenience is case this is called using the values of a dictionary, which cannot hold nil
        if attributeValue as? NSNull != nil || attributeValue == nil {
            
            return NSNull()
        }
        
        switch attributeDescription!.attributeType {
            
        // invalid types
        case .UndefinedAttributeType, .ObjectIDAttributeType:
            
            NSException(name: NSInternalInconsistencyException, reason: ".UndefinedAttributeType and .ObjectIDAttributeType attributes cannot be converted to JSON", userInfo: nil).raise()
            
            return NSObject()
            
        // no conversion
        case .Integer16AttributeType, .Integer32AttributeType, .Integer64AttributeType, .DecimalAttributeType, .DoubleAttributeType, .FloatAttributeType, .BooleanAttributeType, .StringAttributeType:
            
            return attributeValue!
            
        // date
        case .DateAttributeType:
            
            let date = attributeValue as NSDate
            return date.ISO8601String()
            
        // data
        case .BinaryDataAttributeType:
            
            let data = attributeValue as NSData
            return data.base64EncodedStringWithOptions(CoreDataAttributeJSONCompatibilityOptions.Base64EncodingOptions)
            
        // transformable
        case .TransformableAttributeType:
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // convert to data
                let data = transformer!.reverseTransformedValue(attributeValue) as NSData
                
                // convert to string (for JSON export)
                return data.base64EncodedStringWithOptions(CoreDataAttributeJSONCompatibilityOptions.Base64EncodingOptions)
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            // convert to data
            let data = transformer!.transformedValue(attributeValue) as NSData
            
            // convert to string (for JSON export)
            return data.base64EncodedStringWithOptions(CoreDataAttributeJSONCompatibilityOptions.Base64EncodingOptions)
        }
    }
    
    /// Converts a JSON-compatible value to a Core Data attribute value.
    /// 
    /// :param: jsonValue The JSON value that will be converted.
    /// :param: attributeName The name the of attribute that will be used to convert the value. Must be a valid attribute.
    /// :returns: A tuple with a Core Data compatible attribute value and a boolean indicating that the conversion was successful.
    func attributeValueForJSONCompatibleValue(jsonValue: AnyObject, forAttribute attributeName: String) -> (AnyObject?, Bool) {
        
        let attributeDescription = self.attributesByName[attributeName] as? NSAttributeDescription
        
        assert(attributeDescription != nil, "Attribute named \(attributeName) not found on entity \(self)")
        
        // if value is NSNull
        if jsonValue as? NSNull != nil {
            
            return (nil, true)
        }
        
        switch attributeDescription!.attributeType {
            
        case .UndefinedAttributeType, .ObjectIDAttributeType:
            return (nil, false)
            
        case .Integer16AttributeType, .Integer32AttributeType, .Integer64AttributeType, .DecimalAttributeType, .DoubleAttributeType, .FloatAttributeType, .BooleanAttributeType:
            
            // try to cast as number
            let number = jsonValue as? NSNumber
            return (number, number != nil)
            
        case .StringAttributeType:
            
            let string = jsonValue as? String
            return (string, string != nil)
            
        case .DateAttributeType:
            
            if let dateString = jsonValue as? String {
                let date = NSDate.dateWithISO8601String(dateString)
                return (date, date != nil)
            }
            
            return (nil, false)
            
        case .BinaryDataAttributeType:
            
            if let dataString = jsonValue as? String {
                let data = NSData(base64EncodedString: dataString, options: CoreDataAttributeJSONCompatibilityOptions.Base64DecodingOptions)
                return (data, data != nil)
            }
            
            return (nil, false)
            
        // transformable attribute type
        case .TransformableAttributeType:
            
            let base64EncodedString = jsonValue as? String
            
            if base64EncodedString == nil {
                
                return (nil, false)
            }
            
            // get data from Base64 string
            let data = NSData(base64EncodedString: base64EncodedString!, options: CoreDataAttributeJSONCompatibilityOptions.Base64DecodingOptions)
            
            if data == nil {
                
                return (nil, false)
            }
            
            // get transformer
            let valueTransformerName = attributeDescription!.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)!
                
                // unarchive
                let transformedValue: AnyObject? = transformer.transformedValue(data)
                
                return (transformedValue, transformedValue != nil)
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)!
            
            // convert to original type
            let reversedTransformedValue: AnyObject? = transformer.reverseTransformedValue(data)
            
            return (reversedTransformedValue, reversedTransformedValue != nil)
        }
    }
}

// MARK: - Convenience Extensions

internal extension NSManagedObject {
    
    func JSONCompatibleValueForAttribute(attributeName: String) -> AnyObject? {
        
        let attributeValue: AnyObject? = self.valueForKey(attributeName)
        
        if attributeValue != nil {
            
            return self.JSONCompatibleValueForAttributeValue(attributeValue!, forAttribute: attributeName)
        }
        
        return nil
    }
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String) -> AnyObject? {
        
        return self.entity.JSONCompatibleValueForAttributeValue(attributeValue, forAttribute: attributeName)
    }
}

// MARK: - Private Extensions

private extension NSDate {
    
    class func ISO8601DateFormatter() -> NSDateFormatter {
        
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : NSDateFormatter? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = NSDateFormatter()
            Static.instance?.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        }
        return Static.instance!
    }
    
    class func dateWithISO8601String(ISO8601String: String) -> NSDate? {
        
        return self.ISO8601DateFormatter().dateFromString(ISO8601String)
    }
    
    func ISO8601String() -> String {
        
        return NSDate.ISO8601DateFormatter().stringFromDate(self)
    }
}

