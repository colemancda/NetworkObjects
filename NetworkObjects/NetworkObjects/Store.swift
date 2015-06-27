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
            if self.privateQueueManagedObjectContext.respondsToSelector("setName:") {
                
                self.privateQueueManagedObjectContext.name = "NetworkObjects.Store Private Managed Object Context"
            }
            
            // listen for notifications (for merging changes)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesFromContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    // MARK: - Requests
    
    /// Performs a search request on the server. The supplied fetch request's predicate must be a NSComparisonPredicate or NSCompoundPredicate instance.
    ///
    ///
    final public func performSearch<T: NSManagedObject>(fetchRequest: NSFetchRequest, URLSession: NSURLSession? = nil, completionBlock: ((ErrorValue<[T]>) -> Void)) -> NSURLSessionDataTask {
        
        assert(self.searchPath != nil, "Cannot perform searches when searchPath is nil")
        
        let entity: NSEntityDescription
        
        if let entityName = fetchRequest.entityName {
            
            entity = self.managedObjectModel.entitiesByName[entityName]!
        }
        else {
            
            entity = fetchRequest.entity!
        }
        
        let searchParameters = fetchRequest.toJSON(self.managedObjectContext, resourceIDAttributeName: self.resourceIDAttributeName)
        
        let request = self.requestForSearchEntity(entityName, withParameters: searchParameters)
        
        let session = URLSession ?? self.defaultURLSession
        
        return session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, taskError: NSError?) -> Void in
            
            do {
                
                try self.validateSearchResponse((data, response, taskError))
            }
            catch {
                
                completionBlock(ErrorValue.Error(error))
                return
            }
            
            
            
        })
        
        // call API method
        
        return self.searchForResource(entity, withParameters: searchParameters, URLSession: URLSession ?? self.defaultURLSession, completionBlock: { (httpError, results) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError, results: nil)
                
                return
            }
            
            // get results as cached resources...
            
            var cachedResults = [NSManagedObject]()
            
            do {
            
            try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
                
                for resourceIDByResourcePath in results! {
                    
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
                
            }
            catch {
                
                completionBlock(error: error, results: nil)
                
                return
            }
            
            // get the corresponding managed objects that belong to the main queue context
            
            var mainContextResults = [NSManagedObject]()
            
            self.managedObjectContext.performBlockAndWait({ () -> Void in
                
                for managedObject in cachedResults {
                    
                    let mainContextManagedObject = self.managedObjectContext.objectWithID(managedObject.objectID)
                    
                    mainContextResults.append(mainContextManagedObject)
                }
            })
            
            completionBlock(error: nil, results: mainContextResults)
        })
    }
    
    public func fetchResource<T: NSManagedObject>(resource: T, URLSession: NSURLSession? = nil, completionBlock: ((error: ErrorType?) -> Void)) -> NSURLSessionDataTask {
        
        let entityName = resource.entity.name!
        
        let resourceID = resource.valueForKey(self.resourceIDAttributeName) as! UInt
        
        return self.fetchEntity(entityName, resourceID: resourceID, URLSession: URLSession, completionBlock: { (error, managedObject) -> Void in
            
            completionBlock(error: error)
        })
    }
    
    public func fetchEntity(name: String, resourceID: UInt, URLSession: NSURLSession? = nil, completionBlock: ((error: ErrorType?, managedObject: NSManagedObject?) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.managedObjectModel.entitiesByName[name]! as NSEntityDescription
        
        return self.getResource(entity, withID: resourceID, URLSession: URLSession ?? self.defaultURLSession, completionBlock: { (error, jsonObject) -> Void in
            
            // error
            if error != nil {
                
                // not found, delete object from cache
                if let error = StoreError.ErrorStatusCode(ServerErrorCode.NotFound) {
                    
                    // delete object on private thread
                    
                    do {
                    
                    try self.privateQueueManagedObjectContext.performErrorBlock({ () -> Void in
                        
                        let (objectID, cacheError) = self.findEntity(entity, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                        
                        if cacheError != nil {
                            
                            deleteError = cacheError
                            
                            return
                        }
                        
                        if objectID != nil {
                            
                            self.privateQueueManagedObjectContext.deleteObject(self.privateQueueManagedObjectContext.objectWithID(objectID!))
                        }
                        
                        // save
                        
                        try self.privateQueueManagedObjectContext.save()
                    })
                    }
                    catch {
                        
                        completionBlock(error: deleteError, managedObject: nil)
                        
                        return
                    }
                }
                
                completionBlock(error: error, managedObject: nil)
                
                return
            }
            
            var managedObject: NSManagedObject?
            
            var contextError: ErrorType?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // get cached resource
                let (resource, cacheError) = self.findOrCreateEntity(entity, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                
                managedObject = resource
                
                if cacheError != nil {
                    
                    contextError = cacheError
                    
                    return
                }
                
                // set values
                let setJSONError = self.setJSONObject(jsonObject!, forManagedObject: managedObject!, context: self.privateQueueManagedObjectContext)
                
                if setJSONError != nil {
                    
                    contextError = setJSONError
                    
                    return
                }
                
                // set date cached
                self.didCacheManagedObject(resource!)
                
                // save
                var saveError: ErrorType?
                
                do {
                    try self.privateQueueManagedObjectContext.save()
                } catch var error as ErrorType {
                    saveError = error
                    
                    contextError = saveError
                    
                    return
                } catch {
                    fatalError()
                }
            })
            
            // error occurred
            if contextError != nil {
                
                completionBlock(error: contextError, managedObject: nil)
                
                return
            }
            
            // get the corresponding managed object that belongs to the main queue context
            var mainContextManagedObject: NSManagedObject?
            
            self.managedObjectContext.performBlockAndWait({ () -> Void in
                
                mainContextManagedObject = self.managedObjectContext.objectWithID(managedObject!.objectID)
            })
            
            completionBlock(error: nil, managedObject: mainContextManagedObject)
        })
    }
    
    public func createEntity(name: String, withInitialValues initialValues: [String: AnyObject]?, URLSession: NSURLSession? = nil, completionBlock: ((error: ErrorType?, managedObject: NSManagedObject?) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.managedObjectModel.entitiesByName[name]! as NSEntityDescription
        
        var jsonValues: [String: AnyObject]?
        
        // convert initial values to JSON
        if initialValues != nil {
            
            jsonValues = entity.JSONObjectFromCoreDataValues(initialValues!, usingResourceIDAttributeName: self.resourceIDAttributeName)
        }
        
        return self.createResource(entity, withInitialValues: jsonValues, URLSession: URLSession ?? self.defaultURLSession, completionBlock: { (httpError, resourceID) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError, managedObject: nil)
                
                return
            }
            
            var managedObject: NSManagedObject?
            
            var error: ErrorType?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // create new entity
                managedObject = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self.privateQueueManagedObjectContext) as? NSManagedObject
                
                // set resourceID
                managedObject!.setValue(resourceID, forKey: self.resourceIDAttributeName)
                
                // set values
                if initialValues != nil {
                    
                    managedObject!.setValuesForKeysWithDictionary(initialValues!, withManagedObjectContext: self.privateQueueManagedObjectContext)
                }
                
                // set date cached
                self.didCacheManagedObject(managedObject!)
                
                // save
                var saveError: ErrorType?
                
                do {
                    try self.privateQueueManagedObjectContext.save()
                } catch var error1 as ErrorType {
                    saveError = error1
                    
                    error = saveError
                    
                    return
                } catch {
                    fatalError()
                }
            })
            
            // error occurred
            if error != nil {
                
                completionBlock(error: error, managedObject: nil)
                
                return
            }
            
            // get the corresponding managed object that belongs to the main queue context
            var mainContextManagedObject: NSManagedObject?
            
            self.managedObjectContext.performBlockAndWait({ () -> Void in
                
                mainContextManagedObject = self.managedObjectContext.objectWithID(managedObject!.objectID)
            })
            
            completionBlock(error: nil, managedObject: mainContextManagedObject)
        })
    }
    
    public func editManagedObject(managedObject: NSManagedObject, changes: [String: AnyObject], URLSession: NSURLSession? = nil, completionBlock: ((error: ErrorType?) -> Void)) -> NSURLSessionDataTask {
        
        // convert new values to JSON
        let jsonValues = managedObject.entity.JSONObjectFromCoreDataValues(changes, usingResourceIDAttributeName: self.resourceIDAttributeName)
        
        // get resourceID
        let resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as! UInt
        
        return self.editResource(managedObject.entity, withID: resourceID, changes: jsonValues, URLSession: URLSession ?? self.defaultURLSession, completionBlock: { (httpError) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError)
                
                return
            }
            
            var error: ErrorType?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // get object on this context
                let contextResource = self.privateQueueManagedObjectContext.objectWithID(managedObject.objectID)
                
                // set values
                contextResource.setValuesForKeysWithDictionary(changes, withManagedObjectContext: self.privateQueueManagedObjectContext)
                
                // set date cached
                self.didCacheManagedObject(contextResource)
                
                // save
                var saveError: ErrorType?
                
                do {
                    try self.privateQueueManagedObjectContext.save()
                } catch var error1 as ErrorType {
                    saveError = error1
                    
                    error = saveError
                    
                    return
                } catch {
                    fatalError()
                }
            })
            
            // hopefully an error did not occur
            completionBlock(error: error)
        })
    }
    
    public func deleteManagedObject(managedObject: NSManagedObject, URLSession: NSURLSession? = nil, completionBlock: ((error: ErrorType?) -> Void)) -> NSURLSessionDataTask {
        
        // get resourceID
        let resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as! UInt
        
        return self.deleteResource(managedObject.entity, withID: resourceID, URLSession: URLSession ?? self.defaultURLSession, completionBlock: { (httpError) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError)
                
                return
            }
            
            var error: ErrorType?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // get object on this context
                let contextResource = self.privateQueueManagedObjectContext.objectWithID(managedObject.objectID)
                
                // delete
                self.privateQueueManagedObjectContext.deleteObject(contextResource)
                
                // save
                var saveError: ErrorType?
                
                do {
                    try self.privateQueueManagedObjectContext.save()
                } catch var error1 as ErrorType {
                    saveError = error1
                    
                    error = saveError
                    
                    return
                } catch {
                    fatalError()
                }
            })
            
            // hopefully an error did not occur
            completionBlock(error: error)
        })
    }
    
    public func performFunction(function functionName: String, forManagedObject managedObject: NSManagedObject, withJSONObject JSONObject: [String: AnyObject]?, URLSession: NSURLSession? = nil, completionBlock: ((error: ErrorType?, functionCode: ServerFunctionCode?, JSONResponse: [String: AnyObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // get resourceID
        let resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as! UInt
        
        return self.performFunction(functionName, onResource: managedObject.entity, withID: resourceID, withJSONObject: JSONObject, URLSession: URLSession ?? self.defaultURLSession, completionBlock: { (error, functionCode, JSONResponse) -> Void in
            
            completionBlock(error: error, functionCode: functionCode, JSONResponse: JSONResponse)
        })
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
        
        urlRequest.HTTPMethod = "POST"
        
        // add JSON data
        
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(parameters, options: self.jsonWritingOption())
        
        urlRequest.HTTPBody = jsonData
        
        return urlRequest
    }
    
    public func requestForCreateEntity(name: String, withInitialValues initialValues: [String: AnyObject]?) -> NSURLRequest {
        
        // build URL
        
        let createResourceURL = self.serverURL.URLByAppendingPathComponent(name)
        
        let request = NSMutableURLRequest(URL: createResourceURL)
        
        request.HTTPMethod = "POST"
        
        // add initial values to request
        if initialValues != nil {
            
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(initialValues!, options: self.jsonWritingOption())
            } catch _ {
                request.HTTPBody = nil
            }
        }
        
        return request
    }
    
    public func requestForEditEntity(name: String, resourceID: UInt, changes: [String: AnyObject]) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(name).URLByAppendingPathComponent("\(resourceID)")
        
        let request = NSMutableURLRequest(URL: resourceURL)
        
        request.HTTPMethod = "PUT"
        
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(changes, options: self.jsonWritingOption())
        
        return request
    }
    
    public func requestForDeleteEntity(name: String, resourceID: UInt) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(name).URLByAppendingPathComponent("\(resourceID)")
        
        let request = NSMutableURLRequest(URL: resourceURL)
        
        request.HTTPMethod = "DELETE"
        
        return request
    }
    
    public func requestForPerformFunction(functionName: String, entityName: String, resourceID: UInt, JSONObject: [String: AnyObject]?) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(entityName).URLByAppendingPathComponent("\(resourceID)").URLByAppendingPathComponent(functionName)
        
        let request = NSMutableURLRequest(URL: resourceURL)
        
        request.HTTPMethod = "POST"
        
        // add HTTP body
        if JSONObject != nil {
            
            request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(JSONObject!, options: self.jsonWritingOption())
        }
        
        return request
    }
    
    // MARK: Notifications
    
    @objc private func mergeChangesFromContextDidSaveNotification(notification: NSNotification) {
        
        self.managedObjectContext.performBlock { () -> Void in
            
            self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    // MARK: Response Validation
    
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
        
        guard let statusCode = ServerStatusCode(rawValue: httpResponse.statusCode) else {
            
            throw StoreError.UnknownServerStatusCode(httpResponse.statusCode)
        }
        
        guard (statusCode.toErrorStatusCode() == nil) else {
            
            throw StoreError.ErrorStatusCode(statusCode.toErrorStatusCode()!)
        }
    }
    
    private func validateSearchResponse(response: DataTaskResponse) throws {
        
        try self.validateSearchResponse(response)
        
        let jsonData = response.0
        
        // no error status code...
        
        guard let jsonResponse = jsonData.toJSON() as? [[String: UInt]] else {
            
            throw StoreError.InvalidServerResponse
        }
        
        // dictionaries must have one key-value pair
        for resultResourceIDByEntityName in jsonResponse {
            
            guard resultResourceIDByEntityName.count == 1 else {
                
                throw StoreError.InvalidServerResponse
            }
        }
        
    }
    
    private func createResource(entity: NSEntityDescription, withInitialValues initialValues: [String: AnyObject]?, URLSession: NSURLSession, completionBlock: ((error: ErrorType?, resourceID: UInt?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForCreateEntity(entity.name!, withInitialValues: initialValues)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            // NSURLSession errors
            if error != nil {
                
                completionBlock(error: error, resourceID: nil)
                
                return
            }
            
            // error status codes
            
            let httpResponse = response as! NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    // custom error description
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let method = "POST"
                        let value = "Permission to create new resource is denied"
                        let frameworkBundle = NSBundle(identifier: "com.colemancda.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode!.rawValue) for \(method) Request"
                        let key = "ErrorCode.\(errorCode!.rawValue).LocalizedDescription.\(method)"
                        
                        let customError = ErrorType(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
                        completionBlock(error: customError, resourceID: nil)
                        
                        return
                    }
                    
                    completionBlock(error: errorCode!.toError(), resourceID: nil)
                    
                    return
                }
                
                // no recognizeable error code
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resourceID: nil)
                
                return
            }
            
            // parse response...
            
            let jsonObject = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String: AnyObject]
            
            if jsonObject == nil {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resourceID: nil)
                
                return
            }
            
            // get the new resource ID
            let resourceIDObject: AnyObject? = jsonObject![self.resourceIDAttributeName]
            
            let resourceID = resourceIDObject as? UInt
            
            if resourceID == nil {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resourceID: nil)
                
                return
            }
            
            // success
            completionBlock(error: nil, resourceID: resourceID)
            
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    private func getResource(entity: NSEntityDescription, withID resourceID: UInt, URLSession: NSURLSession, completionBlock: ((error: ErrorType?, resource: [String: AnyObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForFetchEntity(entity.name!, resourceID: resourceID)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, resource: nil)
                
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let frameworkBundle = NSBundle(identifier: "com.colemancda.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode!.rawValue) for GET Request"
                        let key = "ErrorCode.\(errorCode!.rawValue).LocalizedDescription.GET"
                        let value = "Access to resource is denied"
                        
                        let customError = ErrorType(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
                        completionBlock(error: customError, resource: nil)
                        
                        return
                    }
                    
                    completionBlock(error: errorCode!.toError(), resource: nil)
                    
                    return
                }
                
                // no recognizeable error code
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resource: nil)
                
                return
            }
            
            // parse response...
            
            let jsonObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? [String: AnyObject]
            
            // invalid JSON response
            if jsonObject == nil {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resource: nil)
                
                return
            }
            
            // validate JSON
            if !self.validateJSONRepresentation(jsonObject!, forEntity: entity) {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resource: nil)
                
                return
            }
            
            // success
            completionBlock(error: nil, resource: jsonObject)
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    private func editResource(entity: NSEntityDescription, withID resourceID: UInt, changes: [String: AnyObject], URLSession: NSURLSession, completionBlock: ((error: ErrorType?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForEditEntity(entity.name!, resourceID: resourceID, changes: changes)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error)
                
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let method = "PUT"
                        let value = "Permission to edit resource is denied"
                        let frameworkBundle = NSBundle(identifier: "com.colemancda.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode!.rawValue) for \(method) Request"
                        let key = "ErrorCode.\(errorCode!.rawValue).LocalizedDescription.\(method)"
                        
                        let customError = ErrorType(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
                        completionBlock(error: customError)
                        
                        return
                    }
                    
                    completionBlock(error: errorCode!.toError())
                    
                    return
                }
                
                // no recognizeable error code
                completionBlock(error: ErrorCode.InvalidServerResponse.toError())
                
                return
            }
            
            // success
            completionBlock(error: nil)
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    private func deleteResource(entity: NSEntityDescription, withID resourceID: UInt, URLSession: NSURLSession, completionBlock: ((error: ErrorType?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForDeleteEntity(entity.name!, resourceID: resourceID)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error)
                
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let method = "DELETE"
                        let value = "Permission to delete resource is denied"
                        let frameworkBundle = NSBundle(identifier: "com.colemancda.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode!.rawValue) for \(method) Request"
                        let key = "ErrorCode.\(errorCode!.rawValue).LocalizedDescription.\(method)"
                        
                        let customError = ErrorType(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
                        completionBlock(error: customError)
                        
                        return
                    }
                    
                    completionBlock(error: errorCode!.toError())
                    
                    return
                }
                
                // no recognizeable error code
                completionBlock(error: ErrorCode.InvalidServerResponse.toError())
                
                return
            }
            
            // success
            completionBlock(error: nil)
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    private func performFunction(functionName: String, onResource entity: NSEntityDescription, withID resourceID: UInt, withJSONObject JSONObject: [String: AnyObject]?, URLSession: NSURLSession, completionBlock: ((error: ErrorType?, functionCode: ServerFunctionCode?, JSONResponse: [String: AnyObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForPerformFunction(functionName, entityName: entity.name!, resourceID: resourceID, JSONObject: JSONObject)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, functionCode: nil, JSONResponse: nil)
                
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            
            let functionCode = ServerFunctionCode(rawValue: httpResponse.statusCode)
            
            // invalid status code
            if functionCode == nil {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), functionCode: nil, JSONResponse: nil)
                
                return
            }
            
            // get response body
            let jsonResponse = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? [String: AnyObject]
            
            completionBlock(error: nil, functionCode: functionCode, JSONResponse: jsonResponse)
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    // MARK: Cache
    
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
    
    private func setJSONObject(JSONObject: [String: AnyObject], forManagedObject managedObject: NSManagedObject, context: NSManagedObjectContext) -> ErrorType? {
        
        // set values...
        
        let entity = managedObject.entity
        
        for (key, jsonValue) in JSONObject {
            
            let attribute = entity.attributesByName[key] as? NSAttributeDescription
            
            if attribute != nil {
                
                let (newValue: AnyObject, valid) = managedObject.entity.attributeValueForJSONCompatibleValue(jsonValue, forAttribute: key)
                
                let currentValue: AnyObject? = managedObject.valueForKey(key)
                
                // set value if not current value
                if (newValue as? NSObject) != (currentValue as? NSObject) {
                    
                    managedObject.setValue(newValue, forKey: key)
                }
            }
            
            let relationship = entity.relationshipsByName[key] as? NSRelationshipDescription
            
            if relationship != nil {
                
                let destinationEntity = relationship!.destinationEntity!
                
                // to-one relationship
                if !relationship!.toMany {
                    
                    // get the resourceID
                    let destinationResourceDictionary = jsonValue as! [String: UInt]
                    
                    // get key and value
                    
                    let destinationResourceEntityName = destinationResourceDictionary.keys.first!
                    
                    let destinationResourceID = destinationResourceDictionary.values.first!
                    
                    let destinationEntity = self.managedObjectModel.entitiesByName[destinationResourceEntityName] as! NSEntityDescription
                    
                    // fetch
                    let (destinationResource, error) = self.findOrCreateEntity(destinationEntity, withResourceID: destinationResourceID, context: context)
                    
                    // halt execution if error
                    if error != nil {
                        
                        return error
                    }
                    
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
                        
                        let destinationEntity = self.managedObjectModel.entitiesByName[destinationResourceEntityName] as! NSEntityDescription
                        
                        let (destinationResource, error) = self.findOrCreateEntity(destinationEntity, withResourceID: destinationResourceID, context: context)
                        
                        // halt execution if error
                        if error != nil {
                            
                            return error
                        }
                        
                        newDestinationResources.append(destinationResource!)
                    }
                    
                    // convert back to NSSet or NSOrderedSet
                    
                    var newValue: AnyObject = {
                        
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
        
        return nil
    }
    
    // MARK: Validation
    
    /** Validates the JSON responses returned in GET requests. */
    private func validateJSONRepresentation(JSONObject: [String: AnyObject], forEntity entity: NSEntityDescription) -> Bool {
        
        for (key, value) in JSONObject {
            
            // validate key
            let attribute = entity.attributesByName[key] as? NSAttributeDescription
            let relationship = entity.relationshipsByName[key] as? NSRelationshipDescription
            
            if attribute == nil && relationship == nil {
                
                return false
            }
            
            // validate value
            if attribute != nil {
                
                let (newValue: AnyObject, valid) = entity.attributeValueForJSONCompatibleValue(value, forAttribute: key)
                
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
        
        let resourceID = JSONValue.values.first!
        
        // verify entity is same kind as destination entity
        let entity = self.managedObjectModel.entitiesByName[entityName] as? NSEntityDescription
        
        if entity == nil {
            
            return false
        }
        
        let validEntity = entity!.isKindOfEntity(relationship.destinationEntity!)
        
        return validEntity
    }
}

// MARK: - Internal Extensions

internal extension NSEntityDescription {
    
    func JSONObjectFromCoreDataValues(values: [String: AnyObject], usingResourceIDAttributeName resourceIDAttributeName: String) -> [String: AnyObject] {
        
        var jsonObject = [String: AnyObject]()
        
        // convert values...
        
        for (key, value) in values {
            
            let attribute = self.attributesByName[key] as? NSAttributeDescription
            
            if attribute != nil {
                
                jsonObject[key] = self.JSONCompatibleValueForAttributeValue(value, forAttribute: key)
            }
            
            let relationship = self.relationshipsByName[key] as? NSRelationshipDescription
            
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
        for (entityName, entity) in self.entitiesByName as [String: NSEntityDescription] {
            
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
        for (entityName, entity) in self.entitiesByName as [String: NSEntityDescription] {
            
            for (propertyName, property) in entity.propertiesByName as [String: NSPropertyDescription] {
                
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
            
            if let relationship = self.entity.relationshipsByName[key] as? NSRelationshipDescription {
                
                // to-one relationships
                if !relationship.toMany {
                    
                    let managedObject = managedObjectContext.objectWithID((value as! NSManagedObject).objectID)
                    
                    newValues[key] = managedObject
                }
                    
                // to-many relationship
                else {
                    
                    var newRelationshipValues = [NSManagedObject]()
                    
                    var arrayValue: [NSManagedObject] = {
                       
                        // set NSSet or NSOrderedSet (which unforunately is not a subclass), also accept NSArray as a convenience
                        
                        if value is [NSManagedObject] {
                            
                            return value as! [NSManagedObject]
                        }
                        
                        if let set = value as? NSSet {
                            
                            return set.allObjects as! [NSManagedObject]
                        }
                        
                        if let orderedSet = value as? NSOrderedSet {
                            
                            return orderedSet.array as! [NSManagedObject]
                        }
                        
                        NSException(name: NSInternalInconsistencyException, reason: "Provided value \(value) for Core Data to-many relationship is not an accepted collection type", userInfo: nil)
                        
                        return []
                    }()
                    
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

private typealias DataTaskResponse = (NSData, NSURLResponse, ErrorType?)
