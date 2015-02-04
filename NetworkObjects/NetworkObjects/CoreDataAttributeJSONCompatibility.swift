//
//  CoreDataAttributeJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

internal extension NSEntityDescription {
    
    // MARK: - Conversion Methods
    
    /** Converts a Core Data attribute value to a JSON-compatible value. */
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String) -> AnyObject? {
        
        let attributeDescription = self.attributesByName[attributeName] as? NSAttributeDescription
        
        assert(attributeDescription != nil, "Attribute named \(attributeName) not found on entity \(self)")
        
        // give value based on attribute type...
        
        // if NSNull then just return NSNull
        // nil attributes can be represented in JSON by NSNull
        if attributeValue as? NSNull != nil || attributeValue == nil {
            
            return NSNull()
        }
        
        if let attributeClassName = attributeDescription!.attributeValueClassName {
            
            switch attributeClassName {
                
                // strings and numbers are standard json data types
            case "NSString", "NSNumber":
                return attributeValue
                
            case "NSDate":
                let date = attributeValue as NSDate
                return date.ISO8601String()
                
            case "NSData":
                let data = attributeValue as NSData
                return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
                
            default:
                return nil
            }
        }
        
        // transformable value type
        if attributeDescription?.attributeType == NSAttributeType.TransformableAttributeType {
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // convert to data
                let data = transformer!.reverseTransformedValue(attributeValue) as NSData
                
                // convert to string (for JSON export)
                return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            // convert to data
            let data = transformer!.transformedValue(attributeValue) as NSData
            
            // convert to string (for JSON export)
            return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
        }
        
        return nil
    }
    
    /// Converts a JSON-compatible value to a Core Data attribute value.
    /// 
    /// :param: JSONCompatibleValue The JSON value that will be converted.
    /// :param: forAttribute The name the of attribute that will be used to convert the value. Must be a valid attribute. 
    /// :returns: A tuble with Core Data compatible attribute value and a boolean indicating the conversion was successful.
    func attributeValueForJSONCompatibleValue(JSONCompatibleValue jsonValue: AnyObject, forAttribute attributeName: String) -> (AnyObject?, Bool) {
        
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
                let data = NSData(base64EncodedString: dataString, options: .allZeros)
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
            let data = NSData(base64EncodedString: base64EncodedString!, options: .allZeros)
            
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
    
    // MARK: - Validate
    
    func isValidConvertedValue(convertedValue: AnyObject, forAttribute attributeName: String) -> Bool {
        
        let attributeDescription = self.attributesByName[attributeName] as? NSAttributeDescription
        
        if attributeDescription == nil {
            
            return false
        }
        
        switch attributeDescription!.attributeType {
            
        case NSAttributeType.UndefinedAttributeType, NSAttributeType.ObjectIDAttributeType:
            return false
            
        case NSAttributeType.Integer16AttributeType, NSAttributeType.Integer32AttributeType, NSAttributeType.Integer64AttributeType, NSAttributeType.DecimalAttributeType, NSAttributeType.DoubleAttributeType, NSAttributeType.FloatAttributeType, NSAttributeType.BooleanAttributeType :
            
            // try to cast as number
            let number = convertedValue as? NSNumber
            return (number != nil)
            
        case NSAttributeType.StringAttributeType:
            
            let string = convertedValue as? String
            return (string != nil)
            
        case NSAttributeType.DateAttributeType:
            
            let date = convertedValue as? NSDate
            return (date != nil)
            
        case NSAttributeType.BinaryDataAttributeType:
            
            let data = convertedValue as? NSData
            return (data != nil)
            
            // transformable value type
        case NSAttributeType.TransformableAttributeType:
            
            // get transformer
            let valueTransformerName = attributeDescription!.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // anything that conforms to NSCoding
                return (convertedValue as? NSCoding != nil)
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            // must convert to NSData
            let data = transformer!.transformedValue(convertedValue) as? NSData
            
            return (data != nil)
            
        }
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

