//
//  CoreDataAttributeJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Conversion Options

/** Static options for CoreData <-> JSON conversion. */
internal class CoreDataAttributeJSONCompatibilityOptions {
    
    class var defaultOptions : CoreDataAttributeJSONCompatibilityOptions {
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : CoreDataAttributeJSONCompatibilityOptions? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = CoreDataAttributeJSONCompatibilityOptions()
        }
        return Static.instance!
    }
    
    var base64EncodingOptions = NSDataBase64EncodingOptions()
    var base64DecodingOptions = NSDataBase64DecodingOptions()
    var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return dateFormatter
    }()
}

// MARK: - Extensions

internal extension NSEntityDescription {
    
    // MARK: - Conversion Methods
    
    /// Converts a Core Data attribute value to a JSON-compatible value.
    /// 
    /// - parameter attributeValue: The Core Data compatible value that will be converted to JSON. Accepts NSNull as a convenience is case this is called using the values of a dictionary, which cannot hold nil. 
    /// - parameter attributeName: The name the of attribute that will be used to convert the value. Must be a valid attribute.
    /// - returns: The converted JSON value.
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String, options: CoreDataAttributeJSONCompatibilityOptions = CoreDataAttributeJSONCompatibilityOptions.defaultOptions) -> AnyObject {
        
        assert(self.attributesByName[attributeName] != nil, "Attribute named \(attributeName) not found on entity \(self)")
        
        let attributeDescription = self.attributesByName[attributeName]!
        
        // give value based on attribute type...
        
        // if NSNull then just return NSNull
        // nil attributes can be represented in JSON by NSNull
        // Accepts NSNull as a convenience is case this is called using the values of a dictionary, which cannot hold nil
        if attributeValue as? NSNull != nil || attributeValue == nil {
            
            return NSNull()
        }
        
        switch attributeDescription.attributeType {
            
        // invalid types
        case .UndefinedAttributeType, .ObjectIDAttributeType:
            
            NSException(name: NSInternalInconsistencyException, reason: ".UndefinedAttributeType and .ObjectIDAttributeType attributes cannot be converted to JSON", userInfo: nil).raise()
            
            return NSObject()
            
        // no conversion
        case .Integer16AttributeType, .Integer32AttributeType, .Integer64AttributeType, .DecimalAttributeType, .DoubleAttributeType, .FloatAttributeType, .BooleanAttributeType, .StringAttributeType:
            
            return attributeValue!
            
        // date
        case .DateAttributeType:
            
            let date = attributeValue as! NSDate
            return options.dateFormatter.stringFromDate(date)
            
        // data
        case .BinaryDataAttributeType:
            
            let data = attributeValue as! NSData
            return data.base64EncodedStringWithOptions(options.base64EncodingOptions)
            
        // transformable
        case .TransformableAttributeType:
            
            // get transformer
            let valueTransformerName = attributeDescription.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // convert to data
                let data = transformer!.reverseTransformedValue(attributeValue) as! NSData
                
                // convert to string (for JSON export)
                return data.base64EncodedStringWithOptions(options.base64EncodingOptions)
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            // convert to data
            let data = transformer!.transformedValue(attributeValue) as! NSData
            
            // convert to string (for JSON export)
            return data.base64EncodedStringWithOptions(options.base64EncodingOptions)
        }
    }
    
    /// Converts a JSON-compatible value to a Core Data attribute value.
    /// 
    /// - parameter jsonValue: The JSON value that will be converted.
    /// - parameter attributeName: The name the of attribute that will be used to convert the value. Must be a valid attribute.
    /// - returns: A tuple with a Core Data compatible attribute value and a boolean indicating that the conversion was successful.
    func attributeValueForJSONCompatibleValue(jsonValue: AnyObject, forAttribute attributeName: String, options: CoreDataAttributeJSONCompatibilityOptions = CoreDataAttributeJSONCompatibilityOptions.defaultOptions) -> (AnyObject?, Bool) {
        
        assert(self.attributesByName[attributeName] != nil, "Attribute named \(attributeName) not found on entity \(self)")
        
        let attributeDescription = self.attributesByName[attributeName]!
        
        // if value is NSNull
        if jsonValue as? NSNull != nil {
            
            return (nil, true)
        }
        
        switch attributeDescription.attributeType {
            
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
                let date = options.dateFormatter.dateFromString(dateString)
                return (date, date != nil)
            }
            
            return (nil, false)
            
        case .BinaryDataAttributeType:
            
            if let dataString = jsonValue as? String {
                let data = NSData(base64EncodedString: dataString, options: options.base64DecodingOptions)
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
            let data = NSData(base64EncodedString: base64EncodedString!, options: options.base64DecodingOptions)
            
            if data == nil {
                
                return (nil, false)
            }
            
            // get transformer
            let valueTransformerName = attributeDescription!.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse (unarchive data)
            if valueTransformerName == nil {
                
                let unarchivedObject: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithData(data!)
                
                return (unarchivedObject, unarchivedObject != nil)
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
    
    func JSONCompatibleValueForAttribute(attributeName: String, options: CoreDataAttributeJSONCompatibilityOptions = CoreDataAttributeJSONCompatibilityOptions.defaultOptions) -> AnyObject? {
        
        let attributeValue: AnyObject? = self.valueForKey(attributeName)
        
        if attributeValue != nil {
            
            return self.JSONCompatibleValueForAttributeValue(attributeValue!, forAttribute: attributeName, options: options)
        }
        
        return nil
    }
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String, options: CoreDataAttributeJSONCompatibilityOptions = CoreDataAttributeJSONCompatibilityOptions.defaultOptions) -> AnyObject? {
        
        return self.entity.JSONCompatibleValueForAttributeValue(attributeValue, forAttribute: attributeName, options: options)
    }
}

