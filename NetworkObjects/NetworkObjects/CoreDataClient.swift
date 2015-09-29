//
//  CoreDataClient.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/28/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreModel

/// This is the class that will fetch and cache data from the server (using CoreData).
public final class CoreDataClient<Client: ClientType> {
    
    // MARK: - Properties
    
    /// The client that will be used for fetching requests.
    public let client: Client
    
    /** The managed object context used for caching. */
    public let managedObjectContext: NSManagedObjectContext
    
    /** A convenience variable for the managed object model. */
    public let managedObjectModel: NSManagedObjectModel
    
    /** The name of the string attribute that holds that resource identifier. */
    public let resourceIDAttributeName: String
    
    /// The name of a for the date attribute that can be optionally added at runtime for cache validation.
    public let dateCachedAttributeName: String?
    
    // MARK: - Private Properties
    
    /** The managed object context running on a background thread for asyncronous caching. */
    private let privateQueueManagedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    
    private let store: CoreDataStore
    
    /// Request queue
    private let requestQueue: NSOperationQueue = {
        
        let queue = NSOperationQueue()
        
        queue.name = "NetworkObjects.CoreDataClient Request Queue"
        
        return queue
        }()
    
    // MARK: - Initialization
    
    deinit {
        // stop recieving 'didSave' notifications from private context
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    /// Creates the Store using the specified options. 
    ///
    /// - Note: The created ```NSManagedObjectContext``` will need a persistent store added 
    /// to its persistent store coordinator.
    public init(managedObjectModel: NSManagedObjectModel, concurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType,
        client: Client,
        resourceIDAttributeName: String = "id",
        dateCachedAttributeName: String? = "dateCached") {
        
            self.client = client
            self.resourceIDAttributeName = resourceIDAttributeName
            self.dateCachedAttributeName = dateCachedAttributeName
            self.managedObjectModel = managedObjectModel.copy() as! NSManagedObjectModel
            
            // setup Core Data stack
            
            // edit model
            
            if self.dateCachedAttributeName != nil {
                
                self.managedObjectModel.addDateCachedAttribute(dateCachedAttributeName!)
            }
            
            self.managedObjectModel.markAllPropertiesAsOptional()
            self.managedObjectModel.addResourceIDAttribute(resourceIDAttributeName)
            
            // setup managed object contexts
            
            self.managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
            self.managedObjectContext.undoManager = nil
            self.managedObjectContext.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            
            self.privateQueueManagedObjectContext.undoManager = nil
            self.privateQueueManagedObjectContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator
            
            // set private context name
            if #available(OSX 10.10, *) {
                self.privateQueueManagedObjectContext.name = "NetworkObjects.CoreDataClient Private Managed Object Context"
            }
            
            // setup CoreDataStore
            guard let store = CoreDataStore(model: client.model, managedObjectContext: privateQueueManagedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
                else { fatalError("Could not create CoreDataStore") }
            
            self.store = store
            
            // listen for notifications (for merging changes)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesFromContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    // MARK: - Actions
    
    /// Performs a search request on the server.
    ///
    /// - precondition: The supplied fetch request's predicate must be a ```NSComparisonPredicate``` or ```NSCompoundPredicate``` instance.
    ///
    public func search<T: NSManagedObject>(fetchRequest: FetchRequest, completionBlock: ((ErrorValue<[T]>) -> Void)) {
        
        guard let entity = self.managedObjectModel.entitiesByName[fetchRequest.entityName]
            else { fatalError("Entity \(fetchRequest.entityName) not found on managed object model") }
        
        requestQueue.addOperationWithBlock {
            
            var objectIDs = [NSManagedObjectID]()
            
            do {
                
                // perform request
                let results = try self.client.search(fetchRequest)
                
                let resourceIDs = results.map({ (resource) -> String in resource.resourceID })
                
                // got response, cache results
                try self.store.cacheResponse(Response.Search(resourceIDs), forRequest: Request.Search(fetchRequest), dateCachedAttributeName: self.dateCachedAttributeName)
                
                // get object IDs
                for resource in results {
                    
                    guard let objectID = try self.store.findEntity(entity, withResourceID: resource.resourceID)
                        else { fatalError("Could not find cached resource: \(resource)") }
                    
                    objectIDs.append(objectID)
                }
            }
            
            catch {
                
                completionBlock(.Error(error))
                
                return
            }
            
            // get the corresponding managed objects that belong to the main queue context
            
            var mainContextResults = [T]()
            
            self.managedObjectContext.performBlockAndWait {
                
                for objectID in objectIDs {
                    
                    let managedObject = self.managedObjectContext.objectWithID(objectID) as! T
                    
                    mainContextResults.append(managedObject)
                }
            }
            
            completionBlock(.Value(mainContextResults))
        }
    }
    
    /** Convenience method for fetching the values of a cached entity. */
    public func fetch<T: NSManagedObject>(managedObject: T, completionBlock: ((ErrorValue<T>) -> Void)) {
        
        let entityName = managedObject.entity.name!
        
        let resourceID = (managedObject as NSManagedObject).valueForKey(self.resourceIDAttributeName) as! String
        
        let resource = Resource(entityName, resourceID)
        
        return self.fetch(resource, completionBlock: { (errorValue: ErrorValue<T>) -> Void in
            
            // forward
            completionBlock(errorValue)
        })
    }
    
    /** Fetches the entity from the server using the specified ```entityName``` and ```resourceID```. */
    public func fetch<T: NSManagedObject>(resource: Resource, completionBlock: ((ErrorValue<T>) -> Void)) {
        
        guard let entity = self.managedObjectModel.entitiesByName[resource.entityName]
            else { fatalError("Entity \(resource.entityName) not found on managed object model") }
        
        requestQueue.addOperationWithBlock {
            
            let objectID: NSManagedObjectID
            
            do {
                // perform request
                let values = try self.client.get(resource)
                
                // got response, cache results
                try self.store.cacheResponse(Response.Get(values), forRequest: Request.Get(resource), dateCachedAttributeName: self.dateCachedAttributeName)
                
                // get object ID
                guard let foundID = try self.store.findEntity(entity, withResourceID: resource.resourceID)
                    else { fatalError("Could not find cached resource: \(resource)") }
                
                objectID = foundID
            }
            
            catch {
                
                completionBlock(.Error(error))
                
                return
            }
            
            // get the corresponding managed object that belongs to the main queue context
            
            var managedObject: T!
            
            self.managedObjectContext.performBlockAndWait {
                
                managedObject = self.managedObjectContext.objectWithID(objectID) as! T
            }
            
            completionBlock(.Value(managedObject))
        }
    }
    
    public func create<T: NSManagedObject>(entityName: String, initialValues: ValuesObject = ValuesObject(), completionBlock: ((ErrorValue<T>) -> Void)) {
        
        guard let entity = self.managedObjectModel.entitiesByName[entityName]
            else { fatalError("Entity \(entityName) not found on managed object model") }
        
        requestQueue.addOperationWithBlock {
            
            let objectID: NSManagedObjectID
            
            do {
                // perform request
                let (resource, values) = try self.client.create(entityName, initialValues: initialValues)
                
                // got response, cache results
                try self.store.cacheResponse(Response.Create(resource.resourceID, values), forRequest: Request.Create(entityName, initialValues), dateCachedAttributeName: self.dateCachedAttributeName)
                
                // get object ID
                guard let foundID = try self.store.findEntity(entity, withResourceID: resource.resourceID)
                    else { fatalError("Could not find cached resource: \(resource)") }
                
                objectID = foundID
            }
            
            catch {
                
                completionBlock(.Error(error))
                
                return
            }
            
            // get the corresponding managed object that belongs to the main queue context
            
            var managedObject: T!
            
            self.managedObjectContext.performBlockAndWait {
                
                managedObject = self.managedObjectContext.objectWithID(objectID) as! T
            }
            
            completionBlock(.Value(managedObject))
        }
    }
    
    public func edit<T: NSManagedObject>(managedObject: T, changes: ValuesObject, completionBlock: ((ErrorType?) -> Void)) {
        
        let entityName = managedObject.entity.name!
        
        let resourceID = (managedObject as NSManagedObject).valueForKey(self.resourceIDAttributeName) as! String
        
        let resource = Resource(entityName, resourceID)
        
        requestQueue.addOperationWithBlock {
            
            do {
                // perform request
                let values = try self.client.edit(resource, changes: changes)
                
                // got response, cache results
                try self.store.cacheResponse(Response.Edit(values), forRequest: Request.Edit(resource, changes), dateCachedAttributeName: self.dateCachedAttributeName)
            }
            
            catch {
                
                completionBlock(error)
                
                return
            }
            
            completionBlock(nil)
        }
    }
    
    public func delete<T: NSManagedObject>(managedObject: T, URLSession: NSURLSession? = nil, completionBlock: ((ErrorType?) -> Void)) {
        
        let entityName = managedObject.entity.name!
        
        let resourceID = (managedObject as NSManagedObject).valueForKey(self.resourceIDAttributeName) as! String
        
        let resource = Resource(entityName, resourceID)
        
        requestQueue.addOperationWithBlock {
            
            do {
                
                try self.client.delete(resource)
                
                // got response, cache results
                try self.store.cacheResponse(Response.Delete, forRequest: Request.Delete(resource), dateCachedAttributeName: self.dateCachedAttributeName)
            }
            
            catch {
                
                completionBlock(error)
                
                return
            }
            
            completionBlock(nil)
        }
    }
    
    public func performFunction<T: NSManagedObject>(function functionName: String, managedObject: T, JSONObject: [String: AnyObject]? = nil, URLSession: NSURLSession? = nil, completionBlock: ((ErrorValue<[String: AnyObject]?>) -> Void))
    
    // MARK: - Notifications
    
    @objc private func mergeChangesFromContextDidSaveNotification(notification: NSNotification) {
        
        self.managedObjectContext.performBlock { () -> Void in
            
            self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
}

// MARK: - Supporting Types

/** Basic wrapper for error / value pairs. */
public enum ErrorValue<T> {
    
    case Error(ErrorType)
    case Value(T)
}
