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
    
    var server: Server!
    
    var store: Store!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // get model
        let model = NSManagedObjectModel.mergedModelFromBundles([NSBundle(identifier: "com.ColemanCDA.NetworkObjectsTests")!])!
        
        // setup server
        let mockServerDataSource = MockServerDataSource()
        
        self.server = Server(dataSource: mockServerDataSource, delegate: nil, managedObjectModel: model)
        
        mockServerDataSource.model = self.server.managedObjectModel
        
        try! self.server.start(onPort: ServerTestingPort)
        
        // setup store
        self.store = Store(managedObjectModel: model, serverURL: NSURL(string: "http://localhost:\(ServerTestingPort)")!, prettyPrintJSON: true)
        
        try! self.store.managedObjectContext.persistentStoreCoordinator!.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    // MARK: - Test Cases
    
    func testDeleteEntityWithOneToOneRelationshipAndNonNilValue() {
        
        // create destination entity
        weak var networkRequestsExpectation = expectationWithDescription("Network Requests Expectation")
        
        store.create("TestInverseRelationships", completionBlock: { (errorValue: ErrorValue<NSManagedObject>) -> Void in
            
            switch errorValue {
                
            case .Error(let error):
                
                XCTFail("Error should have not been produced. \(error)")
                
                networkRequestsExpectation?.fulfill()
                
                return
                
            case .Value(let value):
                
                // create entity
                self.store.create("TestRelationships", initialValues: ["oneToOne" : value], completionBlock: { (errorValue: ErrorValue<NSManagedObject>) -> Void in
                    
                    switch errorValue {
                        
                    case .Error(let error):
                        
                        XCTFail("Error should have not been produced. \(error)")
                        
                        networkRequestsExpectation?.fulfill()
                        
                        return
                        
                    case .Value(let value):
                        
                        // delete entity
                        self.store.delete(value, completionBlock: { (error) -> Void in
                            
                            if error != nil {
                                
                                XCTFail("Error should have not been produced. \(error)")
                                
                                networkRequestsExpectation?.fulfill()
                                
                                return
                            }
                            
                            networkRequestsExpectation?.fulfill()
                            
                        })
                    }
                })
            }
        })
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
