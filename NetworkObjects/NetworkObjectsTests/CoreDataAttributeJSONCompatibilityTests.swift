//
//  CoreDataAttributeJSONCompatibilityTests.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/8/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import XCTest
import CoreData
import ExSwift

class CoreDataAttributeJSONCompatibilityTests: XCTestCase {
    
    // MARK: - Properties
    
    var testModel: NSManagedObjectModel!
    
    var testAttributesEntity: NSEntityDescription!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // create model
        self.testModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(identifier: "com.ColemanCDA.NetworkObjectsTests")!])!
        
        self.testAttributesEntity = self.testModel.entitiesByName["TestAttributes"] as NSEntityDescription
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    // MARK: - Convert JSON to CoreData Test Cases
    
    func testConvertJSONNullToCoreDataNil() {
        
        let null = NSNull()
        
        // set nil to all the attributes
        for (attributeName, attribute) in self.testAttributesEntity.attributesByName as [String: NSAttributeDescription] {
            
            let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(null, forAttribute: attributeName)
            
            XCTAssert(valid, "Conversion should be valid")
            
            XCTAssert(convertedValue == nil, "Converted value should be nil")
        }
    }
    
    func testConvertJSONStringToCoreDataString() {
        
        let sampleString = "sampleString"
        
        let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(sampleString, forAttribute: "stringAttribute")
        
        XCTAssert(valid, "Conversion should be valid")
        
        XCTAssert(convertedValue as? String == sampleString, "Converted value should equal original value")
    }
    
    func testConvertJSONBoolToCoreDataBool() {
        
        let jsonValue = true as NSNumber
        
        let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(jsonValue, forAttribute: "boolAttribute")
        
        XCTAssert(valid, "Conversion should be valid")
        
        XCTAssert(convertedValue as? Bool == jsonValue, "Converted value should equal original value")
    }
    
    func testConvertJSONIntegerToCoreDataInteger() {
        
        let jsonValue = Int(100) as NSNumber
        
        let integerAttributes = ["int16Attribute", "int32Attribute", "int64Attribute"]
        
        for attributeName in integerAttributes {
            
            let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(jsonValue, forAttribute: attributeName)
            
            XCTAssert(valid, "Conversion should be valid")
            
            XCTAssert(convertedValue as? Int == jsonValue, "Converted value should equal original value")
        }
    }
    
    func testConvertJSONFloatToCoreDataFloat() {
        
        let jsonValue = Float(1.11) as NSNumber
        
        let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(jsonValue, forAttribute: "floatAttribute")
        
        XCTAssert(valid, "Conversion should be valid")
        
        XCTAssert(convertedValue as? Float == jsonValue, "Converted value should equal original value")
    }
    
    func testConvertJSONDateToCoreDataDate() {
        
        let date = NSDate()
        
        let jsonDateString = CoreDataAttributeJSONCompatibilityOptions.defaultOptions.dateFormatter.stringFromDate(date)
        
        let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(jsonDateString, forAttribute: "dateAttribute")
        
        XCTAssert(valid, "Conversion should be valid")
        
        let convertedDate = convertedValue as? NSDate
        
        XCTAssert(convertedDate != nil, "Converted value \(convertedValue) should be NSDate instance")
        
        let truncatedOriginalTimeIntervalSince1970 = Double(UInt(date.timeIntervalSince1970))
        
        XCTAssert(convertedDate!.timeIntervalSince1970 == truncatedOriginalTimeIntervalSince1970, "Converted Value \(convertedDate!) should equal original date \(date)")
    }
    
    func testConvertJSONBinaryDataToCoreDataBinaryData() {
        
        let data = "SampleData".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        let base64String = data.base64EncodedStringWithOptions(CoreDataAttributeJSONCompatibilityOptions.defaultOptions.base64EncodingOptions)
        
        let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(base64String, forAttribute: "dataAttribute")
        
        XCTAssert(valid, "Conversion should be valid")
        
        XCTAssert(convertedValue as? NSData == data, "Converted value should equal original value")
    }
    
    func testConvertJSONDefaultTransformerTranformedValueToCoreDataTranformedValue() {
        
        let archivedDictionary = ["key": "value"] as NSDictionary
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(archivedDictionary)
        
        let base64String = data.base64EncodedStringWithOptions(CoreDataAttributeJSONCompatibilityOptions.defaultOptions.base64EncodingOptions)
        
        let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(base64String, forAttribute: "defaultTransformer")
        
        XCTAssert(valid, "Conversion should be valid")
        
        XCTAssert(convertedValue as? NSDictionary == archivedDictionary, "Converted Value should be original archived dictionary")
    }
    
    // MARK: - Convert Garbage JSON to CoreData Test Cases
    
    func testConvertGarbageJSONDefaultTransformerTranformedValueToCoreDataTranformedValue() {
        
        let data = "GarbageData".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        
        let (convertedValue: AnyObject?, valid) = testAttributesEntity.attributeValueForJSONCompatibleValue(data, forAttribute: "defaultTransformer")
        
        XCTAssert(!valid, "Conversion should be invalid")
        
        XCTAssert(convertedValue == nil, "Converted Value should be nil")
    }
    
    // MARK: - Convert CoreData to JSON Cases
    
    func testConvertCoreDataNilToJSONNull() {
        
        let nilValue: AnyObject? = nil
        
        let jsonValue: AnyObject? = testAttributesEntity.JSONCompatibleValueForAttributeValue(nilValue, forAttribute: "stringAttribute")
        
        XCTAssert(jsonValue === NSNull(), "Converted value should be NSNull singleton")
    }
}