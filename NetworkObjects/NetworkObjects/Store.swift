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
    
    /** The name of a for the date attribute that can be optionally added at runtime for cache validation. */
    public let dateCachedAttributeName: String?
    
    /** The name of the Integer attribute that holds that resource identifier. */
    public let resourceIDAttributeName: String
    
    /** The path that the NetworkObjects server uses for search requests. If not specified, doing a search request will produce an error. */
    public let searchPath: String?
    
    /** This setting determines whether JSON requests made to the server will contain whitespace or not. */
    public let prettyPrintJSON: Bool
    
    /** The URL of the NetworkObjects server that this client will connect to. */
    public let serverURL: NSURL
    
    // MARK: - Private Properties
    
    /** The managed object context running on a background thread for asyncronous caching. */
    private let privateQueueManagedObjectContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    
    /** A convenience variable for the managed object model. */
    private let model: NSManagedObjectModel
    
    // MARK: - Initialization
    
    deinit {
        // stop recieving 'didSave' notifications from private context
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    public init(persistentStoreCoordinator: NSPersistentStoreCoordinator,
        managedObjectContextConcurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType,
        serverURL: NSURL,
        prettyPrintJSON: Bool = false,
        resourceIDAttributeName: String = "id",
        dateCachedAttributeName: String?,
        searchPath: String?) {
        
        self.serverURL = serverURL
        self.dateCachedAttributeName = dateCachedAttributeName
        self.searchPath = searchPath
        self.prettyPrintJSON = prettyPrintJSON
        self.resourceIDAttributeName = resourceIDAttributeName
        
        // setup managed object contexts
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: managedObjectContextConcurrencyType)
        self.managedObjectContext.undoManager = nil
        self.managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        self.model = persistentStoreCoordinator.managedObjectModel
        
        self.privateQueueManagedObjectContext.undoManager = nil
        self.privateQueueManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        // listen for notifications (for merging changes)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesFromContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    // MARK: - Requests
    
    /** Performs a search request on the server. The supplied fetch request's predicate must be a NSComparisonPredicate instance. */
    public func performSearch(fetchRequest: NSFetchRequest, URLSession: NSURLSession = NSURLSession.sharedSession(), completionBlock: ((error: NSError?, results: [NSManagedObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build JSON request from fetch request
        
        var jsonObject = [String: AnyObject]()
        
        // optional comparison predicate
        
        let predicate = fetchRequest.predicate as? NSComparisonPredicate
        
        if predicate != nil && predicate?.predicateOperatorType != NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            jsonObject[SearchParameter.PredicateKey.rawValue] = predicate?.leftExpression.keyPath
            
            // convert from Core Data to JSON
            let jsonValue: AnyObject? = fetchRequest.entity!.JSONObjectFromCoreDataValues([predicate!.leftExpression.keyPath: predicate!.rightExpression.constantValue], usingResourceIDAttributeName: self.resourceIDAttributeName).values.first
            
            jsonObject[SearchParameter.PredicateValue.rawValue] = jsonValue
            
            jsonObject[SearchParameter.PredicateOperator.rawValue] = predicate?.predicateOperatorType.rawValue
            
            jsonObject[SearchParameter.PredicateOption.rawValue] = predicate?.options.rawValue
            
            jsonObject[SearchParameter.PredicateModifier.rawValue] = predicate?.comparisonPredicateModifier.rawValue
        }
        
        // other fetch parameters
        
        if fetchRequest.fetchLimit != 0 {
            jsonObject[SearchParameter.FetchLimit.rawValue] = fetchRequest.fetchLimit
        }
        
        if fetchRequest.fetchOffset != 0 {
            jsonObject[SearchParameter.FetchOffset.rawValue] = fetchRequest.fetchOffset
        }
        
        jsonObject[SearchParameter.IncludesSubentities.rawValue] = fetchRequest.includesSubentities
        
        // sort descriptors
        
        if fetchRequest.sortDescriptors!.count != 0 {
            
            var jsonSortDescriptors = [[String: AnyObject]]()
            
            for sort in fetchRequest.sortDescriptors as [NSSortDescriptor] {
                
                jsonSortDescriptors.append([sort.sortKey()! : sort.ascending])
            }
            
            jsonObject[SearchParameter.SortDescriptors.rawValue] = jsonSortDescriptors
        }
        
        // call API method
        
        return self.searchForResource(fetchRequest.entity!, withParameters: jsonObject, URLSession: URLSession, completionBlock: { (httpError, results) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError, results: nil)
                
                return
            }
            
            // get results as cached resources...
            
            var cachedResults = [NSManagedObject]()
            
            var error: NSError?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                for resourcePathByResourceID in results! {
                    
                    let resourceID = UInt(resourcePathByResourceID.keys.first!.toInt()!)
                    
                    let resourcePath = resourcePathByResourceID.values.first
                    
                    // get the entity
                    
                    let entities = self.model.entitiesByName as [String: NSEntityDescription]
                    
                    let entity = entities[resourcePath!]
                    
                    let (resource, cacheError) = self.findOrCreateEntity(entity!, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                    
                    if cacheError != nil {
                        
                        error = cacheError
                        
                        return
                    }
                    
                    cachedResults.append(resource!)
                    
                    // save
                    
                    var saveError: NSError?
                    
                    if !self.privateQueueManagedObjectContext.save(&saveError) {
                        
                        error = saveError
                        
                        return
                    }
                }
            })
            
            // error occurred
            if error != nil {
                
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
    
    public func fetchEntity(name: String, resourceID: UInt, URLSession: NSURLSession = NSURLSession.sharedSession(), completionBlock: ((error: NSError?, managedObject: NSManagedObject?) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.model.entitiesByName[name]! as NSEntityDescription
        
        return self.getResource(entity, withID: resourceID, URLSession: URLSession, completionBlock: { (error, jsonObject) -> Void in
            
            // error
            if error != nil {
                
                // not found, delete object from cache
                if error!.code == ServerStatusCode.NotFound.rawValue {
                    
                    // delete object on private thread
                    
                    var deleteError: NSError?
                    
                    self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                        
                        let (objectID, cacheError) = self.findEntity(entity, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                        
                        if cacheError != nil {
                            
                            deleteError = cacheError
                            
                            return
                        }
                        
                        if objectID != nil {
                            
                            self.privateQueueManagedObjectContext.deleteObject(self.privateQueueManagedObjectContext.objectWithID(objectID!))
                        }
                        
                        // save
                        
                        var saveError: NSError?
                        
                        if !self.privateQueueManagedObjectContext.save(&saveError) {
                            
                            deleteError = saveError
                            
                            return
                        }
                    })
                    
                    if deleteError != nil {
                        
                        completionBlock(error: deleteError, managedObject: nil)
                        
                        return
                    }
                }
                
                completionBlock(error: error, managedObject: nil)
                
                return
            }
            
            var managedObject: NSManagedObject?
            
            var contextError: NSError?
            
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
                var saveError: NSError?
                
                if !self.privateQueueManagedObjectContext.save(&saveError) {
                    
                    contextError = saveError
                    
                    return
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
    
    public func createEntity(name: String, withInitialValues initialValues: [String: AnyObject]?, URLSession: NSURLSession = NSURLSession.sharedSession(), completionBlock: ((error: NSError?, managedObject: NSManagedObject?) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.model.entitiesByName[name]! as NSEntityDescription
        
        var jsonValues: [String: AnyObject]?
        
        // convert initial values to JSON
        if initialValues != nil {
            
            jsonValues = entity.JSONObjectFromCoreDataValues(initialValues!, usingResourceIDAttributeName: self.resourceIDAttributeName)
        }
        
        return self.createResource(entity, withInitialValues: jsonValues, URLSession: URLSession, completionBlock: { (httpError, resourceID) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError, managedObject: nil)
                
                return
            }
            
            var managedObject: NSManagedObject?
            
            var error: NSError?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // create new entity
                managedObject = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self.privateQueueManagedObjectContext) as? NSManagedObject
                
                // set resourceID
                managedObject?.setValue(resourceID, forKey: self.resourceIDAttributeName)
                
                // set values
                if initialValues != nil {
                    
                    for (key, value) in initialValues! {
                        
                        // Core Data cannot hold NSNull
                        if let null = value as? NSNull {
                            
                            managedObject!.setValue(nil, forKey: key)
                        }
                        else {
                            managedObject!.setValue(value, forKey: key)
                        }
                    }
                }
                
                // set date cached
                self.didCacheManagedObject(managedObject!)
                
                // save
                var saveError: NSError?
                
                if !self.privateQueueManagedObjectContext.save(&saveError) {
                    
                    error = saveError
                    
                    return
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
    
    public func editManagedObject(managedObject: NSManagedObject, changes: [String: AnyObject], URLSession: NSURLSession = NSURLSession.sharedSession(), completionBlock: ((error: NSError?) -> Void)) -> NSURLSessionDataTask {
        
        // convert new values to JSON
        let jsonValues = managedObject.entity.JSONObjectFromCoreDataValues(changes, usingResourceIDAttributeName: self.resourceIDAttributeName)
        
        // get resourceID
        let resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as UInt
        
        return self.editResource(managedObject.entity, withID: resourceID, changes: jsonValues, URLSession: URLSession, completionBlock: { (httpError) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError)
                
                return
            }
            
            var error: NSError?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // get object on this context
                let contextResource = self.privateQueueManagedObjectContext.objectWithID(managedObject.objectID)
                
                // set values
                for (key, value) in changes {
                    
                    // Core Data cannot hold NSNull
                    if let null = value as? NSNull {
                        
                        contextResource.setValue(nil, forKey: key)
                    }
                    else {
                        contextResource.setValue(value, forKey: key)
                    }
                }
                
                // set date cached
                self.didCacheManagedObject(contextResource)
                
                // save
                var saveError: NSError?
                
                if !self.privateQueueManagedObjectContext.save(&saveError) {
                    
                    error = saveError
                    
                    return
                }
            })
            
            // hopefully an error did not occur
            completionBlock(error: error)
        })
    }
    
    public func deleteManagedObject(managedObject: NSManagedObject, URLSession: NSURLSession = NSURLSession.sharedSession(), completionBlock: ((error: NSError?) -> Void)) -> NSURLSessionDataTask {
        
        // get resourceID
        let resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as UInt
        
        return self.deleteResource(managedObject.entity, withID: resourceID, URLSession: URLSession, completionBlock: { (httpError) -> Void in
            
            if httpError != nil {
                
                completionBlock(error: httpError)
                
                return
            }
            
            var error: NSError?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // get object on this context
                let contextResource = self.privateQueueManagedObjectContext.objectWithID(managedObject.objectID)
                
                // delete
                self.privateQueueManagedObjectContext.deleteObject(contextResource)
                
                // save
                var saveError: NSError?
                
                if !self.privateQueueManagedObjectContext.save(&saveError) {
                    
                    error = saveError
                    
                    return
                }
            })
            
            // hopefully an error did not occur
            completionBlock(error: error)
        })
    }
    
    public func performFunction(function functionName: String, forManagedObject managedObject: NSManagedObject, withJSONObject JSONObject: [String: AnyObject]?, URLSession: NSURLSession = NSURLSession.sharedSession(), completionBlock: ((error: NSError?, functionCode: ServerFunctionCode?, JSONResponse: [String: AnyObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // get resourceID
        let resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as UInt
        
        return self.performFunction(functionName, onResource: managedObject.entity, withID: resourceID, withJSONObject: JSONObject, URLSession: URLSession, completionBlock: { (error, functionCode, JSONResponse) -> Void in
            
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
        
        let jsonData = NSJSONSerialization.dataWithJSONObject(parameters, options: self.jsonWritingOption(), error: nil)!
        
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
            
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(initialValues!, options: self.jsonWritingOption(), error: nil)
        }
        
        return request
    }
    
    public func requestForEditEntity(name: String, resourceID: UInt, changes: [String: AnyObject]) -> NSURLRequest {
        
        let resourceURL = self.serverURL.URLByAppendingPathComponent(name).URLByAppendingPathComponent("\(resourceID)")
        
        let request = NSMutableURLRequest(URL: resourceURL)
        
        request.HTTPMethod = "PUT"
        
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(changes, options: self.jsonWritingOption(), error: nil)!
        
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
            
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(JSONObject!, options: self.jsonWritingOption(), error: nil)!
        }
        
        return request
    }
    
    // MARK: - Private Methods
    
    private func mergeChangesFromContextDidSaveNotification(notification: NSNotification) {
        
        self.managedObjectContext.performBlock { () -> Void in
            
            self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    private func jsonWritingOption() -> NSJSONWritingOptions {
        
        if self.prettyPrintJSON {
            
            return NSJSONWritingOptions.PrettyPrinted
        }
            
        else {
            
            return NSJSONWritingOptions.allZeros
        }
    }
    
    // MARK: HTTP API
    
    // The API private methods separate the JSON validation and HTTP requests from Core Data caching.
    
    /** Makes the actual search request to the server based on JSON input. */
    private func searchForResource(entity: NSEntityDescription, withParameters parameters:[String: AnyObject], URLSession: NSURLSession, completionBlock: ((error: NSError?, results: [[String: String]]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let urlRequest = self.requestForSearchEntity(entity.name!, withParameters: parameters)
        
        let dataTask = URLSession.dataTaskWithRequest(urlRequest, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, results: nil)
            }
            
            let httpResponse = response as NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode) for Search Request"
                        let key = "ErrorCode.\(errorCode).LocalizedDescription.Search"
                        
                        let customError = NSError(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: "Permission to perform search is denied", comment: comment)])
                        
                        completionBlock(error: customError, results: nil)
                        
                        return
                    }
                    
                    completionBlock(error: errorCode!.toError(), results: nil)
                    
                    return
                }
                
                // no recognizeable error code
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), results: nil)
                
                return
            }
            
            // no error status code...
            
            let jsonResponse = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [[String: String]]
            
            // invalid JSON response
            if jsonResponse == nil {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), results: nil)
                
                return
            }
            
            // dictionaries must have one key-value pair
            for resultResourcePathByResourceID in jsonResponse! {
                
                let dictionary = resultResourcePathByResourceID as NSDictionary
                
                if dictionary.count != 1 {
                    
                    completionBlock(error: ErrorCode.InvalidServerResponse.toError(), results: nil)
                    
                    return
                }
            }
            
            
            // JSON has been validated
            completionBlock(error: nil, results: jsonResponse)
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    private func createResource(entity: NSEntityDescription, withInitialValues initialValues: [String: AnyObject]?, URLSession: NSURLSession, completionBlock: ((error: NSError?, resourceID: UInt?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForCreateEntity(entity.name!, withInitialValues: initialValues)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            // NSURLSession errors
            if error != nil {
                
                completionBlock(error: error, resourceID: nil)
                
                return
            }
            
            // error status codes
            
            let httpResponse = response as NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    // custom error description
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let method = "POST"
                        let value = "Permission to create new resource is denied"
                        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode) for \(method) Request"
                        let key = "ErrorCode.\(errorCode).LocalizedDescription.\(method)"
                        
                        let customError = NSError(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
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
            
            let jsonObject = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as? [String: AnyObject]
            
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
    
    private func getResource(entity: NSEntityDescription, withID resourceID: UInt, URLSession: NSURLSession, completionBlock: ((error: NSError?, resource: [String: AnyObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForFetchEntity(entity.name!, resourceID: resourceID)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, resource: nil)
            }
            
            let httpResponse = response as NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode) for GET Request"
                        let key = "ErrorCode.\(errorCode).LocalizedDescription.GET"
                        let value = "Access to resource is denied"
                        
                        let customError = NSError(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
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
            
            let jsonObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String: AnyObject]
            
            // invalid JSON response
            if jsonObject == nil {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resource: nil)
                
                return
            }
            
            // make sure every key in jsonObject is a valid key
            
            for (key, value) in jsonObject! {
                
                let attribute = entity.attributesByName[key] as? NSAttributeDescription
                
                let relationship = entity.relationshipsByName[key] as? NSRelationshipDescription
                
                if attribute == nil && relationship == nil {
                    
                    completionBlock(error: ErrorCode.InvalidServerResponse.toError(), resource: nil)
                    
                    return
                }
            }
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    private func editResource(entity: NSEntityDescription, withID resourceID: UInt, changes: [String: AnyObject], URLSession: NSURLSession, completionBlock: ((error: NSError?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForEditEntity(entity.name!, resourceID: resourceID, changes: changes)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error)
            }
            
            let httpResponse = response as NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let method = "PUT"
                        let value = "Permission to edit resource is denied"
                        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode) for \(method) Request"
                        let key = "ErrorCode.\(errorCode).LocalizedDescription.\(method)"
                        
                        let customError = NSError(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
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
    
    private func deleteResource(entity: NSEntityDescription, withID resourceID: UInt, URLSession: NSURLSession, completionBlock: ((error: NSError?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForDeleteEntity(entity.name!, resourceID: resourceID)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error)
            }
            
            let httpResponse = response as NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.rawValue {
                
                let errorCode = ErrorCode(rawValue: httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let method = "DELETE"
                        let value = "Permission to delete resource is denied"
                        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(errorCode) for \(method) Request"
                        let key = "ErrorCode.\(errorCode).LocalizedDescription.\(method)"
                        
                        let customError = NSError(domain: NetworkObjectsErrorDomain, code: errorCode!.rawValue, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle!, value: value, comment: comment)])
                        
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
    
    private func performFunction(functionName: String, onResource entity: NSEntityDescription, withID resourceID: UInt, withJSONObject JSONObject: [String: AnyObject]?, URLSession: NSURLSession, completionBlock: ((error: NSError?, functionCode: ServerFunctionCode?, JSONResponse: [String: AnyObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let request = self.requestForPerformFunction(functionName, entityName: entity.name!, resourceID: resourceID, JSONObject: JSONObject)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, functionCode: nil, JSONResponse: nil)
                
                return
            }
            
            let httpResponse = response as NSHTTPURLResponse
            
            let functionCode = ServerFunctionCode(rawValue: httpResponse.statusCode)
            
            // invalid status code
            if functionCode == nil {
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), functionCode: nil, JSONResponse: nil)
                
                return
            }
            
            // get response body
            let jsonResponse = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String: AnyObject]
            
            completionBlock(error: nil, functionCode: functionCode, JSONResponse: jsonResponse)
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    // MARK: Cache
    
    private func setupDateCachedAttributeWithAttributeName(dateCachedAttributeName: String) {
        
        // add a date attribute to managed object model
        for (entityName, entity) in self.model.entitiesByName as [String: NSEntityDescription] {
            
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
    
    private func didCacheManagedObject(managedObject: NSManagedObject) {
        
        // set the date cached attribute
        if self.dateCachedAttributeName != nil {
            
            managedObject.setValue(NSDate(), forKey: self.dateCachedAttributeName!)
        }
    }
    
    private func findEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, context: NSManagedObjectContext) -> (NSManagedObjectID?, NSError?) {
        
        // get cached resource...
        
        let fetchRequest = NSFetchRequest(entityName: entity.name!)
        
        fetchRequest.fetchLimit = 1
        
        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        
        // create predicate
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        // fetch
        
        var error: NSError?
        
        let results = context.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObjectID]
        
        // halt execution if error
        if error != nil {
            
            return (nil, error)
        }
        
        var objectID = results?.first
        
        return (objectID, nil)
    }
    
    private func findOrCreateEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, context: NSManagedObjectContext) -> (NSManagedObject?, NSError?) {
        
        // get cached resource...
        
        let fetchRequest = NSFetchRequest(entityName: entity.name!)
        
        fetchRequest.fetchLimit = 1
        
        // create predicate
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        fetchRequest.returnsObjectsAsFaults = false
        
        // fetch
        
        var error: NSError?
        
        let results = context.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject]
        
        // halt execution if error
        if error != nil {
            
            return (nil, error!)
        }
        
        var resource = results?.first
        
        // create cached resource if not found
        
        if resource == nil {
            
            // create a new entity
            
            resource = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as? NSManagedObject
            
            // set resource ID
            
            resource?.setValue(resourceID, forKey: self.resourceIDAttributeName)
        }
        
        return (resource!, nil)
    }
    
    private func setJSONObject(JSONObject: [String: AnyObject], forManagedObject managedObject: NSManagedObject, context: NSManagedObjectContext) -> NSError? {
        
        // set values...
        
        let entity = managedObject.entity
        
        for (key, jsonValue) in JSONObject {
            
            let attribute = entity.attributesByName[key] as? NSAttributeDescription
            
            if attribute != nil {
                
                let newValue: AnyObject = managedObject.attributeValueForJSONCompatibleValue(jsonValue, forAttribute: key)!
                
                let currentValue: AnyObject = managedObject.valueForKey(key)!
                
                // set value if not current value
                if !newValue.isEqual(currentValue) {
                    
                    managedObject.setValue(newValue, forKey: key)
                }
            }
            
            let relationship = entity.relationshipsByName[key] as? NSRelationshipDescription
            
            if relationship != nil {
                
                let destinationEntity = relationship!.destinationEntity!
                
                // to-one relationship
                if !relationship!.toMany {
                    
                    // get the resourceID
                    let destinationResourceID = jsonValue as UInt
                    
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
                    
                    let destinationResourceIDs = jsonValue as [UInt]
                    
                    let currentValues = managedObject.valueForKey(key)! as NSSet
                    
                    let destinationResources = NSMutableSet()
                    
                    for destinationResourceID in destinationResourceIDs {
                        
                        let (destinationResource, error) = self.findOrCreateEntity(destinationEntity, withResourceID: destinationResourceID, context: context)
                        
                        // halt execution if error
                        if error != nil {
                            
                            return error
                        }
                        
                        destinationResources.addObject(destinationResources)
                    }
                    
                    // set value if not current value
                    if !destinationResources.isEqualToSet(currentValues) {
                        
                        managedObject.setValue(destinationResources, forKey: key)
                    }
                }
            }
        }
        
        return nil
    }
}

// MARK: - Extensions

private extension NSEntityDescription {
    
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
                    let destinationResource = value as NSManagedObject
                    
                    let destinationResourceID = destinationResource.valueForKey(resourceIDAttributeName) as UInt
                    
                    jsonObject[key] = destinationResourceID
                }
                
                // to-many relationship
                else {
                    
                    let destinationResources = value as? NSSet
                    
                    var destinationResourceIDs = [UInt]()
                    
                    for destinationResource in destinationResources!.allObjects as [NSManagedObject] {
                        
                        let destinationResourceID = destinationResource.valueForKey(resourceIDAttributeName) as UInt
                        
                        destinationResourceIDs.append(destinationResourceID)
                    }
                    
                    jsonObject[key] = destinationResourceIDs
                }
            }
        }
        
        return jsonObject
    }
}

