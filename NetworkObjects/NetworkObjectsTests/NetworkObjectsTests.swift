//
//  NetworkObjectsTests.swift
//  NetworkObjectsTests
//
//  Created by Alsey Coleman Miller on 9/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import XCTest
import CoreData
import NetworkObjects

class NetworkObjectsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFrameworkVersion() {
                
        let shortFrameworkVersion = NetworkObjectsFrameworkBundle.infoDictionary!["CFBundleShortVersionString"] as! String
        
        let frameworkVersion = NetworkObjectsFrameworkBundle.infoDictionary![kCFBundleVersionKey as String]! as! String
        
        if frameworkVersion == "TRAVISCI" {
            
            print("Skipping framework version assertion, running from Travis CI")
            
            return
        }
        
        print("Testing NetworkObjects \(shortFrameworkVersion) Build \(frameworkVersion)")
        
        XCTAssert(shortFrameworkVersion != "1", "Short framework version (\(shortFrameworkVersion)) should not equal 1")
        
        XCTAssert(UInt(frameworkVersion) > 1, "Framework version (\(frameworkVersion)) should be greater than 1")
    }
    
    func testStoreInit() {
        // This is an example of a functional test case.
        
        let store = Store(managedObjectModel: NSManagedObjectModel(), managedObjectContextConcurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType, serverURL: NSURL(string: "http://localhost:8080")!, prettyPrintJSON: true, resourceIDAttributeName: "id", dateCachedAttributeName: "dateCached", searchPath: "search")
        
        XCTAssert(store.dynamicType === Store.self, "Store should have been initialized")
    }
}