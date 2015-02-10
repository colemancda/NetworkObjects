//
//  NetworkObjectsTests.swift
//  NetworkObjectsTests
//
//  Created by Alsey Coleman Miller on 9/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#if os(iOS)
import UIKit
#endif
#if os(OSX)
import AppKit
#endif

import Foundation
import XCTest
import CoreData
import NetworkObjects
import ExSwift

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
        
        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")!
        
        let shortFrameworkVersion = frameworkBundle.infoDictionary!["CFBundleShortVersionString"] as String
        
        let frameworkVersion = frameworkBundle.infoDictionary![kCFBundleVersionKey]! as String
        
        if frameworkVersion == "TRAVISCI" {
            
            println("Skipping framework version assertion, running from Travis CI")
            
            return
        }
        
        println("Testing NetworkObjects \(shortFrameworkVersion) Build \(frameworkVersion)")
        
        XCTAssert(shortFrameworkVersion != "1", "Short framework version (\(shortFrameworkVersion)) should not equal 1")
        
        XCTAssert(frameworkVersion.toUInt()! > 1, "Framework version (\(frameworkVersion)) should be greater than 1")
    }
    
    func testStoreInit() {
        // This is an example of a functional test case.
        
        let store = Store(managedObjectModel: NSManagedObjectModel(), managedObjectContextConcurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType, serverURL: NSURL(string: "http://localhost:8080")!, prettyPrintJSON: true, resourceIDAttributeName: "id", dateCachedAttributeName: "dateCached", searchPath: "search")
        
        XCTAssert(store.dynamicType === Store.self, "Store should have been initialized")
    }
    
    func testServerInit() {
        // This is an example of a functional test case.
        
        
        
        XCTAssert(true, "Pass")
    }
}
