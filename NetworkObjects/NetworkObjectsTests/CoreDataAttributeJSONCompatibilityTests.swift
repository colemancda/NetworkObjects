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
    
    // MARK: - Convert JSON to Core Data Tests
    
    func testConvertJSONNullToCoreData() {
        
        let null = NSNull()
        
        // create entity
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        
        entity.name = "TestConvertJSONNullToCoreData"
        
        let attribute = NSAttributeDescription()
        
        attribute.name = "nilStringAttribute"
        
        attribute.attributeType = NSAttributeType.StringAttributeType
        
        entity.properties = [attribute]
        
        let (newValue: AnyObject?, valid) = entity.attributeValueForJSONCompatibleValue(null, forAttribute: attribute.name)
        
        XCTAssert(valid, "Conversion should be valid")
        
        XCTAssert(newValue == nil, "Converted value should be nil")
    }
    
    // MARK: - Convert Core Data to JSON Tests
    

}