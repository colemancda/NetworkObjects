//
//  Store.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/10/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

/** This is the class that will fetch and cache data from the server. */

public class Store {
    
    // MARK: - Properties
    
    /** The managed object context used for caching. */
    public let managedObjectContext: NSManagedObjectContext
    
    /** A convenience variable for the managed object model. */
    public let managedObjectModel: NSManagedObjectModel
    
    /** The name of a for the date attribute that can be optionally added at runtime for cache validation. */
    public let dateCachedAttributeName: String?
    
    /** The name of the Integer attribute that holds that resource identifier. */
    public let resourceIDAttributeName: String
    
    /** The path that the NetworkObjects server uses for search requests. If not specified, doing a search request will produce an exception. */
    public var searchPath: String?
    
    /** This setting determines whether JSON requests made to the server will contain whitespace or not. */
    public var prettyPrintJSON: Bool
    
    /** The URL of the NetworkObjects server that this client will connect to. */
    public var serverURL: NSURL
    
    /** The defualt URL session this store will use for requests. Requests can still be made to the server using another URL session. */
    public var defaultURLSession: NSURLSession = NSURLSession.sharedSession()
    
    // MARK: - Private Properties
    
    /** The managed object context running on a background thread for asyncronous caching. */
    private let privateQueueManagedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    
    // MARK: - Initialization
    
    deinit {
        // stop recieving 'didSave' notifications from private context
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    /** Creates the Store using the specified options. The created managedObjectContext will need a persistent store added to its store coordinator. */
    public init(managedObjectModel: NSManagedObjectModel,
        managedObjectContextConcurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType,
        serverURL: NSURL,
        prettyPrintJSON: Bool = false,
        resourceIDAttributeName: String = "id",
        dateCachedAttributeName: String? = "dateCached",
        searchPath: String? = "search") {
            
            self.serverURL = serverURL
            self.searchPath = searchPath
            self.prettyPrintJSON = prettyPrintJSON
            self.resourceIDAttributeName = resourceIDAttributeName
            self.dateCachedAttributeName = dateCachedAttributeName
            self.managedObjectModel = managedObjectModel.copy() as! NSManagedObjectModel
            
            // edit model
            
            if self.dateCachedAttributeName != nil {
                
                self.managedObjectModel.addDateCachedAttribute(dateCachedAttributeName!)
            }
            
            self.managedObjectModel.markAllPropertiesAsOptional()
            self.managedObjectModel.addResourceIDAttribute(resourceIDAttributeName)
            
            // setup managed object contexts
            self.managedObjectContext = NSManagedObjectContext(concurrencyType: managedObjectContextConcurrencyType)
            self.managedObjectContext.undoManager = nil
            self.managedObjectContext.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            
            self.privateQueueManagedObjectContext.undoManager = nil
            self.privateQueueManagedObjectContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator
            
            // set private context name
            if #available(OSX 10.10, *) {
                self.privateQueueManagedObjectContext.name = "NetworkObjects.Store Private Managed Object Context"
            }
            
            // listen for notifications (for merging changes)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesFromContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    // MARK: - Actions
    
    /// Performs a search request on the server.
    ///
    /// - precondition: The supplied fetch request's predicate must be a ```NSComparisonPredicate``` or ```NSCompoundPredicate``` instance.
    ///
    final public func search<T: NSManagedObject>(fetchRequest: NSFetchRequest, URLSession: NSURLSession? = nil, completionBlock: ((ErrorValue<[T]>) -> Void)) -> NSURLSessionDataTask {
        
        guard self.searchPath != nil else {
            
            fatalError("Cannot perform searches when searchPath is nil")
        }
        
        let entity: NSEntityDescription
        
        if let entityName = fetchRequest.entityName {
            
            entity = self.managedObjectModel.entitiesByName[entityName]!
        }
        else {
            
            entity = fetchRequest.entity!
        }
        
        let searchParameters = fetchRequest.toJSON(self.managedObjectContext, resourceIDAttributeName: self.resourceIDAttributeName)
        
        let request = self.requestForSearchEntity(entity.name!, withParameters: searchParameters)
        
        let session = URLSession ?? self.defaultURLSession
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: {[weak self] (data: NSData?, response: NSURLResponse?, taskError: NSError?) -> Void in
            
            if self == nil { return }
            
            let searchResponse: [T]
            
            do {
                
                searchResponse = try self!.cacheSearchResponse((data, response, taskError))
            }
            catch {
                
                completionBlock(ErrorValue.Error(error))
                return
            }
            
            completionBlock(ErrorValue.Value(searchResponse))
        })!
        
        dataTask.resume()
        
        return dataTask
    }
    
    /** Convenience method for fetching the values of a cached entity. */
    public func fetch<T: NSManagedObject>(managedObject: T, URLSession: NSURLSession? = nil, completionBlock: ((ErrorValue<T>) -> Void)) -> NSURLSessionDataTask {
        
        let entityName = managedObject.entity.name!
        
        let resourceID = (managedObject as NSManagedObject).valueForKey(self.resourceIDAttributeName) as! UInt
        
        return self.fetch(entityName, resourceID: resourceID, URLSession: URLSession, completionBlock: { (errorValue: ErrorValue<T>) -> Void in
            
            // forward
            completionBlock(errorValue)
        })
    }
    
    /** Fetches the entity from the server using the specified ```entityName``` and ```resourceID```. */
    public func fetch<T: NSManagedObject>(name: String, resourceID: UInt, URLSession: NSURLSession? = nil, completionBlock: ((ErrorValue<T>) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.managedObjectModel.entitiesByName[name]! as NSEntityDescription
        
        let request = self.requestForFetchEntity(name, resourceID: resourceID)
        
        let session = URLSession ?? self.defaultURLSession
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: {[weak self] (data: NSData?, response: NSURLResponse?, taskError: NSError?) -> Void in
            
            if self == nil { return }
            
            let managedObject: T
            
            do {
                
                managedObject = try self!.cacheFetchResponse((data, response, taskError), forEntity: entity, resourceID: resourceID)
            }
            catch {
                
                completionBlock(ErrorValue.Error(error))
                return
            }
            
            completionBlock(ErrorValue.Value(managedObject))
        })!
        
        dataTask.resume()
        
        return dataTask
        
    }
    
    public func create<T: NSManagedObject>(entityName: String, initialValues: [String: AnyObject]? = nil, URLSession: NSURLSession? = nil, completionBlock: ((ErrorValue<T>) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.managedObjectModel.entitiesByName[entityName]! as NSEntityDescription
        
        let jsonValues: [String: AnyObject]?
        
        // convert initial values to JSON
        if initialValues != nil {
            
            jsonValues = entity.JSONObjectFromCoreDataValues(initialValues!, usingResourceIDAttributeName: self.resourceIDAttributeName)
        }
        else {
            
            jsonValues = nil
        }
        
        let request = self.requestForCreateEntity(entity.name!, initialValues: jsonValues)
        
        let session = URLSession ?? self.defaultURLSession
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: {[weak self] (data: NSData?, response: NSURLResponse?, taskError: NSError?) -> Void in
            
            if self == nil { return }
            
            let managedObject: T
            
            do {
                
                managedObject = try self!.cacheCreateResponse((data, response, taskError), forEntity: entity, initialValues: initialValues)
            }
            catch {
                
                completionBlock(ErrorValue.Error(error))
                return
            }
            
            completionBlock(ErrorValue.Value(managedObject))
            })!
        
        dataTask.resume()
        
        return dataTask
    }
    
    public func edit<T: NSManagedObject>(managedObject: T, changes: [String: AnyObject], URLSession: NSURLSession? = nil, completionBlock: ((ErrorType?) -> Void)) -> NSURLSessionDataTask {
        
        // convert new values to JSON
        let jsonValues = managedObject.entity.JSONObjectFromCoreDataValues(changes, usingResourceIDAttributeName: self.resourceIDAttributeName)
        
        let resourceID = (managedObject as NSManagedObject).valueForKey(self.resourceIDAttributeName) as! UInt
        
        let request = self.requestForEditEntity(managedObject.entity.name!, resourceID: resourceID, changes: jsonValues)
        
        let session = URLSession ?? self.defaultURLSession
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: {[weak self] (data: NSData?, response: NSURLResponse?, taskError: NSError?) -> Void in
            
            if self == nil { return }
            
            do {
                
                try self!.cacheEditResponse((data, response, taskError), managedObject: managedObject, changes: changes)
            }
            catch {
                
                completionBlock(error)
                return
            }
            
            completionBlock(nil)
        })!
        
        dataTask.resume()
        
        return dataTask
    }
    
    public func delete<T: NSManagedObject>(managedObject: T, URLSession: NSURLSession? = nil, completionBlock: ((ErrorType?) -> Void)) -> NSURLSessionDataTask {
        
        let resourceID = (managedObject as NSManagedObject).valueForKey(self.resourceIDAttributeName) as! UInt
        
        let request = self.requestForDeleteEntity(managedObject.entity.name!, resourceID: resourceID)
        
        let session = URLSession ?? self.defaultURLSession
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: {[weak self] (data: NSData?, response: NSURLResponse?, taskError: NSError?) -> Void in
            
            if self == nil { return }
            
            do {
                
                try self!.cacheDeleteResponse((data, response, taskError), managedObject: managedObject)
            }
            catch {
                
                completionBlock(error)
                return
            }
            
            completionBlock(nil)
            })!
        
        dataTask.resume()
        
        return dataTask
    }
    
    public func performFunction<T: NSManagedObject>(function functionName: String, managedObject: T, JSONObject: [String: AnyObject]? = nil, URLSession: NSURLSession? = nil, completionBlock: ((ErrorValue<[String: AnyObject]?>) -> Void)) -> NSURLSessionDataTask {
        
        let resourceID = (managedObject as NSManagedObject).valueForKey(self.resourceIDAttributeName) as! UInt
        
        let request = self.requestForPerformFunction(functionName, entityName: managedObject.entity.name!, resourceID: resourceID, JSONObject: JSONObject)
        
        let session = URLSession ?? self.defaultURLSession
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: {[weak self] (data: NSData?, response: NSURLResponse?, taskError: NSError?) -> Void in
            
            if self == nil { return }
            
            let functionResponse: [String: AnyObject]?
            
            do {
                
                functionResponse = try self!.validateFunctionResponse((data, response, taskError))
            }
            catch {
                
                completionBlock(ErrorValue.Error(error))
                return
            }
            
            completionBlock(ErrorValue.Value(functionResponse))
        })!
        
        dataTask.resume()
        
        return dataTask
    }
    
    // MARK: - Build URL Requests
    
    /** Builds the NSURLRequest for GET requests. Subclasses can override this to add headers. */
    public func requestForFetchEntity(name: String, resourceID: UInt) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(name).URLByAppendingPathComponent("\(resourceID)")
        
        let request = NSURLRequest(URL: resourceURL)
        
        return request
    }
    
    public func requestForSearchEntity(name: String, withParameters parameters: [String: AnyObject]) -> NSURLRequest {
        
        // build URL
        
        let searchURL = self.serverURL.URLByAppendingPathComponent(self.searchPath!).URLByAppendingPathComponent(name)
        
        let urlRequest = NSMutableURLRequest(URL: searchURL)
        
        urlRequest.HTTPMethod = RequestType.Search.HTTPMethod.rawValue
        
        urlRequest.HTTPBody = NSData(JSON: parameters, prettyPrintJSON: self.prettyPrintJSON)
        
        return urlRequest
    }
    
    public func requestForCreateEntity(name: String, initialValues: [String: AnyObject]?) -> NSURLRequest {
        
        // build URL
        
        let createResourceURL = self.serverURL.URLByAppendingPathComponent(name)
        
        let request = NSMutableURLRequest(URL: createResourceURL)
        
        request.HTTPMethod = RequestType.Create.HTTPMethod.rawValue
        
        // add initial values to request
        if initialValues != nil {
            
            request.HTTPBody = NSData(JSON: initialValues!, prettyPrintJSON: self.prettyPrintJSON)!
        }
        
        return request
    }
    
    public func requestForEditEntity(name: String, resourceID: UInt, changes: [String: AnyObject]) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(name).URLByAppendingPathComponent("\(resourceID)")
        
        let request = NSMutableURLRequest(URL: resourceURL)
        
        request.HTTPMethod = RequestType.Edit.HTTPMethod.rawValue
        
        request.HTTPBody = NSData(JSON: changes, prettyPrintJSON: self.prettyPrintJSON)
        
        return request
    }
    
    public func requestForDeleteEntity(name: String, resourceID: UInt) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(name).URLByAppendingPathComponent("\(resourceID)")
        
        let request = NSMutableURLRequest(URL: resourceURL)
        
        request.HTTPMethod = RequestType.Delete.HTTPMethod.rawValue
        
        return request
    }
    
    public func requestForPerformFunction(functionName: String, entityName: String, resourceID: UInt, JSONObject: [String: AnyObject]?) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(entityName).URLByAppendingPathComponent("\(resourceID)").URLByAppendingPathComponent(functionName)
        
        let request = NSMutableURLRequest(URL: resourceURL)
        
        request.HTTPMethod = RequestType.Function.HTTPMethod.rawValue
        
        // add HTTP body
        if JSONObject != nil {
            
            request.HTTPBody = NSData(JSON: JSONObject!, prettyPrintJSON: prettyPrintJSON)
        }
        
        return request
    }
    
    // MARK: - Response Validation
    
    // The API private methods separate the JSON validation and HTTP requests from Core Data caching.
    
    /** Validates the HTTP response from the server. */
    private func validateServerResponse(response: DataTaskResponse) throws {
        
        let (_, urlResponse, error) = response
        
        guard error == nil else {
            
            throw error!
        }
        
        // error codes
        
        guard let httpResponse = urlResponse as? NSHTTPURLResponse else {
            
            throw StoreError.InvalidServerResponse
        }
        
        guard let statusCode = StatusCode(rawValue: httpResponse.statusCode) else {
            
            throw StoreError.UnknownStatusCode(httpResponse.statusCode)
        }
        
        let errorStatusCode = statusCode.toErrorStatusCode()
        
        guard (errorStatusCode == nil) else {
            
            throw StoreError.ErrorStatusCode(errorStatusCode!)
        }
    }
    
    private func validateSearchResponse(response: DataTaskResponse) throws -> [[String: UInt]] {
        
        try self.validateServerResponse(response)
        
        guard let jsonData = response.0,
            let jsonResponse = jsonData.toJSON() as? [[String: UInt]] else {
            
            throw StoreError.InvalidServerResponse
        }
        
        // dictionaries must have one key-value pair
        for resultResourceIDByEntityName in jsonResponse {
            
            guard resultResourceIDByEntityName.count == 1 else {
                
                throw StoreError.InvalidServerResponse
            }
        }
        
        return jsonResponse
    }
    
    private func validateFetchResponse(response: DataTaskResponse, forEntity entity: NSEntityDescription) throws -> [String: AnyObject] {
        
        try self.validateServerResponse(response)
        
        // parse response...
        guard let jsonData = response.0,
            let jsonObject = jsonData.toJSON() as? [String: AnyObject]
            where self.validateJSONRepresentation(jsonObject, forEntity: entity) else {
            
            throw StoreError.InvalidServerResponse
        }
        
        return jsonObject
    }
    
    private func validateCreateResponse(response: DataTaskResponse) throws -> UInt {
        
        try self.validateServerResponse(response)
        
        guard let jsonData = response.0,
            let jsonObject = jsonData.toJSON() as? [String: UInt]
            where jsonObject.count == 1,
            let resourceIDAttributeName = jsonObject.keys.first
            where resourceIDAttributeName == self.resourceIDAttributeName,
            let resourceID = jsonObject.values.first else {
            
            throw StoreError.InvalidServerResponse
        }
        
        return resourceID
    }
    
    private func validateEditResponse(response: DataTaskResponse) throws {
        
        try self.validateServerResponse(response)
    }
    
    private func validateDeleteResponse(response: DataTaskResponse) throws {
        
        try self.validateServerResponse(response)
    }
    
    private func validateFunctionResponse(response: DataTaskResponse) throws -> [String: AnyObject]? {
        
        try self.validateServerResponse(response)
        
        guard let jsonData = response.0, let jsonObject = jsonData.toJSON() as? [String: UInt] else {
            
            throw StoreError.InvalidServerResponse
        }
        
        return jsonObject
    }
    
    // MARK: - Cache Response
    
    private func cacheSearchResponse<T: NSManagedObject>(response: DataTaskResponse) throws -> [T] {
        
        let jsonResponse = try self.validateSearchResponse(response)
        
        // get results as cached resources...
        
        var cachedResults = [NSManagedObject]()
        
        try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
            
            for resourceIDByResourcePath in jsonResponse {
                
                let resourcePath = resourceIDByResourcePath.keys.first!
                
                let resourceID = resourceIDByResourcePath.values.first!
                
                // get the entity
                
                let entities = self.managedObjectModel.entitiesByName as [String: NSEntityDescription]
                
                let entity = entities[resourcePath]
                
                let resource: NSManagedObject = try self.findOrCreateEntity(entity!, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                
                cachedResults.append(resource)
                
                // save
                
                try self.privateQueueManagedObjectContext.save()
            }
        })
        
        // get the corresponding managed objects that belong to the main queue context
        
        var mainContextResults = [NSManagedObject]()
        
        self.managedObjectContext.performBlockAndWait({ () -> Void in
            
            for managedObject in cachedResults {
                
                let mainContextManagedObject = self.managedObjectContext.objectWithID(managedObject.objectID)
                
                mainContextResults.append(mainContextManagedObject)
            }
        })
        
        return mainContextResults as! [T]
    }
    
    private func cacheFetchResponse<T: NSManagedObject>(response: DataTaskResponse, forEntity entity: NSEntityDescription, resourceID: UInt) throws -> T {
        
        let jsonObject: [String: AnyObject]
        
        do {
            
            jsonObject = try validateFetchResponse(response, forEntity: entity)
        }
        catch StoreError.ErrorStatusCode(ErrorStatusCode.NotFound) {
            
            try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
                
                let objectID = try self.findEntity(entity, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                
                if objectID != nil {
                    
                    self.privateQueueManagedObjectContext.deleteObject(self.privateQueueManagedObjectContext.objectWithID(objectID!))
                    
                    try self.privateQueueManagedObjectContext.save()
                }
            })
            
            throw StoreError.ErrorStatusCode(ErrorStatusCode.NotFound)
        }
        
        // cache recieved object...
        var managedObject: NSManagedObject!
        
        try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
            
            // get cached resource
            managedObject = try self.findOrCreateEntity(entity, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
            
            // set values
            try self.setJSONObject(jsonObject, forManagedObject: managedObject!, context: self.privateQueueManagedObjectContext)
            
            // set date cached
            self.didCacheManagedObject(managedObject)
            
            try self.privateQueueManagedObjectContext.save()
        })
        
        // get the corresponding managed object that belongs to the main queue context
        var mainContextManagedObject: NSManagedObject!
        
        self.managedObjectContext.performBlockAndWait({ () -> Void in
            
            mainContextManagedObject = self.managedObjectContext.objectWithID(managedObject!.objectID)
        })
        
        return mainContextManagedObject as! T
    }
    
    private func cacheCreateResponse<T: NSManagedObject>(response: DataTaskResponse, forEntity entity: NSEntityDescription, initialValues: [String: AnyObject]?) throws -> T {
        
        let resourceID = try self.validateCreateResponse(response)
        
        var managedObject: NSManagedObject!
        
        try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
            
            // create new entity
            managedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: self.privateQueueManagedObjectContext)
            
            // set resourceID
            managedObject.setValue(resourceID, forKey: self.resourceIDAttributeName)
            
            // set values
            if initialValues != nil {
                
                managedObject.setValuesForKeysWithDictionary(initialValues!, withManagedObjectContext: self.privateQueueManagedObjectContext)
            }
            
            // set date cached
            self.didCacheManagedObject(managedObject)
            
            // save
            try self.privateQueueManagedObjectContext.save()
        })
        
        // get the corresponding managed object that belongs to the main queue context
        var mainContextManagedObject: NSManagedObject!
        
        self.managedObjectContext.performBlockAndWait({ () -> Void in
            
            mainContextManagedObject = self.managedObjectContext.objectWithID(managedObject.objectID)
        })
        
        return mainContextManagedObject as! T
    }
    
    private func cacheEditResponse<T: NSManagedObject>(response: DataTaskResponse, managedObject: T, changes: [String: AnyObject]) throws {
        
        try self.validateEditResponse(response)
        
        try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
            
            // get object on this context
            let contextResource = self.privateQueueManagedObjectContext.objectWithID(managedObject.objectID)
            
            // set values
            contextResource.setValuesForKeysWithDictionary(changes, withManagedObjectContext: self.privateQueueManagedObjectContext)
            
            // set date cached
            self.didCacheManagedObject(contextResource)
            
            try self.privateQueueManagedObjectContext.save()
        })
    }
    
    private func cacheDeleteResponse<T: NSManagedObject>(response: DataTaskResponse, managedObject: T) throws {
        
        try validateDeleteResponse(response)
        
        try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
            
            // get object on this context
            let contextResource = self.privateQueueManagedObjectContext.objectWithID(managedObject.objectID)
            
            // delete
            self.privateQueueManagedObjectContext.deleteObject(contextResource)
            
            // save
            try self.privateQueueManagedObjectContext.save()
        })
    }
    
    // MARK: - Cache
    
    private func didCacheManagedObject(managedObject: NSManagedObject) {
        
        // set the date cached attribute
        if self.dateCachedAttributeName != nil {
            
            managedObject.setValue(NSDate(), forKey: self.dateCachedAttributeName!)
        }
    }
    
    private func findEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, context: NSManagedObjectContext) throws -> NSManagedObjectID? {
        
        // get cached resource...
        
        let fetchRequest = NSFetchRequest(entityName: entity.name!)
        
        fetchRequest.fetchLimit = 1
        
        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        
        fetchRequest.includesSubentities = false
        
        // create predicate
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        // fetch
        
        let results = try context.executeFetchRequest(fetchRequest) as! [NSManagedObjectID]
        
        let objectID = results.first
        
        return objectID
    }
    
    private func findOrCreateEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, context: NSManagedObjectContext) throws -> NSManagedObject {
        
        // get cached resource...
        
        let fetchRequest = NSFetchRequest(entityName: entity.name!)
        
        fetchRequest.fetchLimit = 1
        
        fetchRequest.includesSubentities = false
        
        // create predicate
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        fetchRequest.returnsObjectsAsFaults = false
        
        // fetch
        
        let results = try context.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        
        var resource = results.first
        
        // create cached resource if not found
        
        if resource == nil {
            
            // create a new entity
            
            resource = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
            
            // set resource ID
            
            resource!.setValue(resourceID, forKey: self.resourceIDAttributeName)
        }
        
        return resource!
    }
    
    private func setJSONObject(JSONObject: [String: AnyObject], forManagedObject managedObject: NSManagedObject, context: NSManagedObjectContext) throws {
        
        // set values...
        
        let entity = managedObject.entity
        
        for (key, jsonValue) in JSONObject {
            
            let attribute = entity.attributesByName[key]
            
            if attribute != nil {
                
                let (newValue, _) = managedObject.entity.attributeValueForJSONCompatibleValue(jsonValue, forAttribute: key)
                
                let currentValue = managedObject.valueForKey(key)
                
                // set value if not current value
                if  (newValue as? NSObject) != (currentValue as? NSObject) {
                    
                    managedObject.setValue(newValue, forKey: key)
                }
            }
            
            let relationship = entity.relationshipsByName[key]
            
            if relationship != nil {
                
                // to-one relationship
                if !relationship!.toMany {
                    
                    // get the resourceID
                    let destinationResourceDictionary = jsonValue as! [String: UInt]
                    
                    // get key and value
                    
                    let destinationResourceEntityName = destinationResourceDictionary.keys.first!
                    
                    let destinationResourceID = destinationResourceDictionary.values.first!
                    
                    let destinationEntity = self.managedObjectModel.entitiesByName[destinationResourceEntityName]!
                    
                    // fetch
                    let destinationResource = try self.findOrCreateEntity(destinationEntity, withResourceID: destinationResourceID, context: context)
                    
                    // set value if not current value
                    if destinationResource !== managedObject.valueForKey(key) {
                        
                        managedObject.setValue(destinationResource, forKey: key)
                    }
                }
                
                // to-many relationship
                else {
                    
                    // get the resourceIDs
                    
                    let destinationResourceIDs = jsonValue as! [[String: UInt]]
                    
                    let currentValues: AnyObject? = managedObject.valueForKey(key)
                    
                    var newDestinationResources = [NSManagedObject]()
                    
                    for destinationResourceDictionary in destinationResourceIDs {
                        
                        // get key and value
                        
                        let destinationResourceEntityName = destinationResourceDictionary.keys.first!
                        
                        let destinationResourceID = destinationResourceDictionary.values.first!
                        
                        let destinationEntity = self.managedObjectModel.entitiesByName[destinationResourceEntityName]!
                        
                        let destinationResource = try self.findOrCreateEntity(destinationEntity, withResourceID: destinationResourceID, context: context)
                        
                        newDestinationResources.append(destinationResource)
                    }
                    
                    // convert back to NSSet or NSOrderedSet
                    
                    let newValue: AnyObject = {
                        
                        if relationship!.ordered {
                            
                            return NSOrderedSet(array: newDestinationResources)
                        }
                        
                        return NSSet(array: newDestinationResources)
                    }()
                    
                    // set value if not current value
                    if !newValue.isEqual(currentValues) {
                        
                        managedObject.setValue(newValue, forKey: key)
                    }
                }
            }
        }
        
        // set nil for values that were not included
        for property in managedObject.entity.properties {
            
            let key = property.name
            
            // omit resourceID attribute and dateCached
            if key == self.resourceIDAttributeName || key == self.dateCachedAttributeName {
                
                // skip
                continue
            }
            
            // no key-value pair found
            if JSONObject[key] == nil {
                
                // only set nil if non-nil, don't wanna fire off notifications
                if managedObject.valueForKey(key) != nil {
                    
                    managedObject.setValue(nil, forKey: key)
                }
            }
        }
    }
    
    // MARK: - Validation
    
    /** Validates the JSON responses returned in GET requests. */
    private func validateJSONRepresentation(JSONObject: [String: AnyObject], forEntity entity: NSEntityDescription) -> Bool {
        
        for (key, value) in JSONObject {
            
            // validate key
            let attribute = entity.attributesByName[key]
            let relationship = entity.relationshipsByName[key]
            
            if attribute == nil && relationship == nil {
                
                return false
            }
            
            // validate value
            if attribute != nil {
                
                let (_, valid) = entity.attributeValueForJSONCompatibleValue(value, forAttribute: key)
                
                if !valid {
                    
                    return false
                }
            }
            
            // relationship
            else {
                
                if !relationship!.toMany {
                    
                    let jsonValue = value as? [String: UInt]
                    
                    if jsonValue == nil {
                        
                        return false
                    }
                    
                    if !self.validateJSONValue(jsonValue!, inRelationship: relationship!) {
                        
                        return false
                    }
                }
                else {
                    
                    let jsonArrayValue = value as? [[String: UInt]]
                    
                    if jsonArrayValue == nil {
                        
                        return false
                    }
                    
                    for jsonValue in jsonArrayValue! {
                        
                        if !self.validateJSONValue(jsonValue, inRelationship: relationship!) {
                            
                            return false
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    /** Validates the individual JSON values in to-one or to-many relationship. */
    private func validateJSONValue(JSONValue: [String: UInt], inRelationship relationship: NSRelationshipDescription) -> Bool {
        
        if JSONValue.count != 1 {
            
            return false
        }
        
        let entityName = JSONValue.keys.first!
        
        // verify entity is same kind as destination entity
        let entity = self.managedObjectModel.entitiesByName[entityName]
        
        if entity == nil {
            
            return false
        }
        
        let validEntity = entity!.isKindOfEntity(relationship.destinationEntity!)
        
        return validEntity
    }
    
    // MARK: Notifications
    
    @objc private func mergeChangesFromContextDidSaveNotification(notification: NSNotification) {
        
        self.managedObjectContext.performBlock { () -> Void in
            
            self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
}

// MARK: - Internal Extensions

internal extension NSEntityDescription {
    
    func JSONObjectFromCoreDataValues(values: [String: AnyObject], usingResourceIDAttributeName resourceIDAttributeName: String) -> [String: AnyObject] {
        
        var jsonObject = [String: AnyObject]()
        
        // convert values...
        
        for (key, value) in values {
            
            let attribute = self.attributesByName[key]
            
            if attribute != nil {
                
                jsonObject[key] = self.JSONCompatibleValueForAttributeValue(value, forAttribute: key)
            }
            
            let relationship = self.relationshipsByName[key]
            
            if relationship != nil {
                
                // to-one relationship
                if !relationship!.toMany {
                    
                    // get the resource ID of the object
                    let destinationResource = value as! NSManagedObject
                    
                    let destinationResourceID = destinationResource.valueForKey(resourceIDAttributeName) as! UInt
                    
                    jsonObject[key] = [destinationResource.entity.name!: destinationResourceID]
                }
                    
                    // to-many relationship
                else {
                    
                    let destinationResources: [NSManagedObject] = {
                        
                        // ordered set
                        if relationship!.ordered {
                            
                            let orderedSet = value as! NSOrderedSet
                            
                            return orderedSet.array as! [NSManagedObject]
                        }
                        
                        // set
                        let set = value as! NSSet
                        
                        return set.allObjects as! [NSManagedObject]
                        
                        }()
                    
                    var destinationResourceIDs = [[String: UInt]]()
                    
                    for destinationResource in destinationResources {
                        
                        let destinationResourceID = destinationResource.valueForKey(resourceIDAttributeName) as! UInt
                        
                        destinationResourceIDs.append([destinationResource.entity.name!: destinationResourceID])
                    }
                    
                    jsonObject[key] = destinationResourceIDs
                }
            }
        }
        
        return jsonObject
    }
}

// MARK: - Private Extensions

private extension NSManagedObjectModel {
    
    func addDateCachedAttribute(dateCachedAttributeName: String) {
        
        // add a date attribute to managed object model
        for (_, entity) in self.entitiesByName as [String: NSEntityDescription] {
            
            if entity.superentity == nil {
                
                // create new (runtime) attribute
                let dateAttribute = NSAttributeDescription()
                dateAttribute.attributeType = NSAttributeType.DateAttributeType
                dateAttribute.name = dateCachedAttributeName
                
                // add to entity
                entity.properties.append(dateAttribute)
            }
        }
    }
    
    func markAllPropertiesAsOptional() {
        
        // add a date attribute to managed object model
        for (_, entity) in self.entitiesByName as [String: NSEntityDescription] {
            
            for (_, property) in entity.propertiesByName as [String: NSPropertyDescription] {
                
                property.optional = true
            }
        }
    }
}

private extension NSManagedObject {
    
    func setValuesForKeysWithDictionary(keyedValues: [String : AnyObject], withManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        
        if self.managedObjectContext != nil {
            
            assert(self.managedObjectContext == managedObjectContext, "reciever does not belong to the provided managedObjectContext")
        }
        
        // make sure relationship values are from managed object context
        
        var newValues = [String: AnyObject]()
        
        for (key, value) in keyedValues {
            
            if let relationship = self.entity.relationshipsByName[key] {
                
                // to-one relationships
                if !relationship.toMany {
                    
                    let managedObject = managedObjectContext.objectWithID((value as! NSManagedObject).objectID)
                    
                    newValues[key] = managedObject
                }
                    
                // to-many relationship
                else {
                    
                    var newRelationshipValues = [NSManagedObject]()
                    
                    guard let arrayValue: [NSManagedObject] = {
                       
                        // set NSSet or NSOrderedSet (which unforunately is not a subclass), also accept NSArray as a convenience
                        
                        if value is [NSManagedObject] {
                            
                            return value as? [NSManagedObject]
                        }
                        
                        if let set = value as? NSSet {
                            
                            return set.allObjects as? [NSManagedObject]
                        }
                        
                        if let orderedSet = value as? NSOrderedSet {
                            
                            return orderedSet.array as? [NSManagedObject]
                        }
                        
                        return nil
                        
                    }() else {
                        
                        fatalError("Provided value \(value) for Core Data to-many relationship is not an accepted collection type")
                    }
                    
                    // get values belonging to managed object context
                    
                    for destinationManagedObject in arrayValue {
                        
                        let managedObject = managedObjectContext.objectWithID(destinationManagedObject.objectID)
                        
                        newRelationshipValues.append(managedObject)
                    }
                    
                    // convert back to NSSet or NSOrderedSet
                    
                    if relationship.ordered {
                        
                        newValues[key] = NSOrderedSet(array: newRelationshipValues)
                    }
                    else {
                        
                        newValues[key] = NSSet(array: newRelationshipValues)
                    }
                }
            }
            
            else {
                
                newValues[key] = value
            }
        }
        
        self.setValuesForKeysWithDictionary(newValues)
    }
}

private typealias DataTaskResponse = (NSData?, NSURLResponse?, ErrorType?)
