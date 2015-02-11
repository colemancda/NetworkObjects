//
//  DeleteTests.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/10/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import XCTest
import CoreData
import ExSwift
import NetworkObjects

class DeleteTests: XCTestCase {
    
    // MARK: - Properties
    
    var testModel: NSManagedObjectModel!
    
    var testServer: Server!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        self.testModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(identifier: "com.ColemanCDA.NetworkObjectsTests")!])!
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    // MARK: - Test Cases
    
    func testDeleteEntityWithOneToOneRelationship() {
        
        
    }
}