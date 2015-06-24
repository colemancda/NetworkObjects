//
//  MockServerDataSource.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/10/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import NetworkObjects

class MockServerDataSource: ServerDataSource {
    
    // MARK: - Properties
    
    var model: NSManagedObjectModel!
    
    var lastResourceIDByEntityName = [String: UInt]()
    
    var lastResourceIDByEntityNameOperationQueue: NSOperationQueue = {
        
        let operationQueue = NSOperationQueue()
        
        operationQueue.name = "MockServerDataSource lastResourceIDByEntityName Access Queue"
        
        operationQueue.maxConcurrentOperationCount = 1
        
        return operationQueue
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
       
        // setup persistent store coordinator
        let psc = NSPersistentStoreCoordinator(managedObjectModel: self.model!)
        
        try! psc.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        
        return psc
    }()
    
    /** Mock function handler mapped by [EntityName : [FunctionName: FunctionHandler]] */
    var mockFunctionHandlers = [String: [String: MockFunctionHandler]]()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Methods
    
    func newResourceIDForEntity(entityName: String) -> UInt {
        
        // create new resourceID
        var newResourceID = UInt(0)
        
        self.lastResourceIDByEntityNameOperationQueue.addOperations([NSBlockOperation(block: { () -> Void in
            
            // get last resource ID and increment by 1
            if let lastResourceID = self.lastResourceIDByEntityName[entityName] {
                
                newResourceID = lastResourceID + 1;
            }
            
            // save new one
            self.lastResourceIDByEntityName[entityName] = newResourceID;
            
        })], waitUntilFinished: true)
        
        return newResourceID
    }
    
    func newManagedObjectContext() -> NSManagedObjectContext {
        
        // create a new managed object context
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        // setup persistent store coordinator
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return managedObjectContext
    }
    
    // MARK: - ServerDataSource
    
    func server(server: Server, managedObjectContextForRequest request: ServerRequest) -> NSManagedObjectContext {
        
        return self.newManagedObjectContext();
    }
    
    func server(server: Server, newResourceIDForEntity entity: NSEntityDescription) -> UInt {
        
        return self.newResourceIDForEntity(entity.name!)
    }
    
    func server(server: Server, functionsForEntity entity: NSEntityDescription) -> [String] {
        
        return self.mockFunctionHandlers[entity.name!]?.keys.array ?? []
    }
    
    func server(server: Server, performFunction functionName: String, forManagedObject managedObject: NSManagedObject, context: NSManagedObjectContext, recievedJsonObject: [String : AnyObject]?, request: ServerRequest, inout userInfo: [String: AnyObject]) -> (ServerFunctionCode, [String : AnyObject]?) {
        
        let completionHandler = self.mockFunctionHandlers[managedObject.entity.name!]![functionName]!
        
        var response: (ServerFunctionCode, [String : AnyObject]?)!
        
        context.performBlockAndWait({ () -> Void in
            
            response = completionHandler(managedObject: managedObject, context: context, recievedJsonObject: recievedJsonObject, request: request)
        })
        
        return response
    }
    
}

/** Block for mocking functions. */
typealias MockFunctionHandler = (managedObject: NSManagedObject, context: NSManagedObjectContext, recievedJsonObject: [String : AnyObject]?, request: ServerRequest) -> (ServerFunctionCode, [String : AnyObject]?)
