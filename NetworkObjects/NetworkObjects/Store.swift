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
    public let resourceIDAttributeName: String = "ID"
    
    /** The path that the NetworkObjects server uses for search requests. If not specified then doing a search request will produce an error. */
    public let searchPath: String?
    
    /** This setting determines whether JSON requests made to the server will contain whitespace or not. */
    public let prettyPrintJSON: Bool = false
    
    /** The URL of the NetworkObjects server that this client will connect to. */
    public let serverURL: NSURL
    
    /**  Resource path strings mapped to entity descriptions. */
    public let entitiesByResourcePath: [String: NSEntityDescription]
    
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
    
    init(persistentStoreCoordinator: NSPersistentStoreCoordinator, managedObjectContextConcurrencyType: NSManagedObjectContextConcurrencyType, serverURL: NSURL, entitiesByResourcePath: [String: NSEntityDescription], prettyPrintJSON: Bool?, resourceIDAttributeName: String?, dateCachedAttributeName: String?, searchPath: String?) {
        
        // set required values
        self.serverURL = serverURL
        self.entitiesByResourcePath = entitiesByResourcePath
        
        // set optional values
        self.dateCachedAttributeName = dateCachedAttributeName
        self.searchPath = searchPath
        
        // set values that have defaults
        if prettyPrintJSON != nil {
            
            self.prettyPrintJSON = prettyPrintJSON!
        }
        if resourceIDAttributeName != nil {
            
            self.resourceIDAttributeName = resourceIDAttributeName!
        }
        
        // setup contexts
        
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
    
    /** Performs a search request on the server. The supplied fetch request's predicate must be a NSComparisonPredicate. */
    public func performSearch(#fetchRequest: NSFetchRequest, URLSession: NSURLSession, completionBlock: ((error: NSError?, results: [NSManagedObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build JSON request from fetch request
        
        var jsonObject = [String: AnyObject]()
        
        // optional comparison predicate
        
        let predicate = fetchRequest.predicate as? NSComparisonPredicate
        
        if predicate != nil && predicate?.predicateOperatorType != NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            jsonObject[SearchParameter.PredicateKey.toRaw()] = predicate?.leftExpression.keyPath
            
            // convert from Core Data to JSON
            let jsonValue: AnyObject? = fetchRequest.entity.JSONObjectFromCoreDataValues([predicate!.leftExpression.keyPath: predicate!.rightExpression.constantValue], usingResourceIDAttributeName: self.resourceIDAttributeName).values.first
            
            jsonObject[SearchParameter.PredicateValue.toRaw()] = jsonValue
            
            jsonObject[SearchParameter.PredicateOperator.toRaw()] = predicate?.predicateOperatorType.toRaw()
            
            jsonObject[SearchParameter.PredicateOption.toRaw()] = predicate?.options.toRaw()
            
            jsonObject[SearchParameter.PredicateModifier.toRaw()] = predicate?.comparisonPredicateModifier.toRaw()
        }
        
        // other fetch parameters
        
        if fetchRequest.fetchLimit != 0 {
            jsonObject[SearchParameter.FetchLimit.toRaw()] = fetchRequest.fetchLimit
        }
        
        if fetchRequest.fetchOffset != 0 {
            jsonObject[SearchParameter.FetchOffset.toRaw()] = fetchRequest.fetchOffset
        }
        
        jsonObject[SearchParameter.IncludesSubentities.toRaw()] = fetchRequest.includesSubentities
        
        // sort descriptors
        
        if fetchRequest.sortDescriptors.count != 0 {
            
            var jsonSortDescriptors = [[String: AnyObject]]()
            
            for sort in fetchRequest.sortDescriptors as [NSSortDescriptor] {
                
                jsonSortDescriptors.append([sort.key!: sort.ascending])
            }
            
            jsonObject[SearchParameter.SortDescriptors.toRaw()] = jsonSortDescriptors
        }
        
        // call API method
        
        return self.searchForResource(fetchRequest.entity, withParameters: jsonObject, URLSession: URLSession, completionBlock: { (error, results) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, results: nil)
                
                return
            }
            
            // get results as cached resources...
            
            var cachedResults = [NSManagedObject]()
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                for resourcePathByResourceID in results! {
                    
                    let resourceID = UInt(resourcePathByResourceID.keys.first!.toInt()!)
                    
                    let resourcePath = resourcePathByResourceID.values.first
                    
                    // get the entity
                    
                    let entity = self.entitiesByResourcePath[resourcePath!]
                    
                    let (resource, error) = self.findOrCreateEntity(entity!, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                    
                    if error != nil {
                        
                        completionBlock(error: error, results: nil)
                        
                        return
                    }
                    
                    cachedResults.append(resource!)
                    
                    // save
                    
                    let saveError = NSErrorPointer()
                    
                    if self.privateQueueManagedObjectContext.save(saveError) {
                        
                        completionBlock(error: saveError.memory, results: nil)
                        
                        return
                    }
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
            
            completionBlock(error: nil, results: mainContextResults)
        })
    }
    
    public func fetchEntity(name: String, resourceID: UInt, URLSession: NSURLSession, completionBlock: ((error: NSError?, managedObject: NSManagedObject?) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.model.entitiesByName[name]! as NSEntityDescription
        
        return self.getResource(entity, withID: resourceID, URLSession: URLSession, completionBlock: { (error, jsonObject) -> Void in
            
            // error
            if error != nil {
                
                // not found, delete object from cache
                if error!.code == ServerStatusCode.NotFound.toRaw() {
                    
                    // delete object on private thread
                    self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                        
                        let (objectID, error) = self.findEntity(entity, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                        
                        if error != nil {
                            
                            completionBlock(error: error, managedObject: nil)
                            
                            return
                        }
                        
                        if objectID != nil {
                            
                            self.privateQueueManagedObjectContext.deleteObject(self.privateQueueManagedObjectContext.objectWithID(objectID!))
                        }
                        
                        // save
                        
                        let saveError = NSErrorPointer()
                        
                        if !self.privateQueueManagedObjectContext.save(saveError) {
                            
                            completionBlock(error: saveError.memory, managedObject: nil)
                            
                            return
                        }
                    })
                }
                
                completionBlock(error: error, managedObject: nil)
                
                return
            }
            
            var managedObject: NSManagedObject?
            
            self.privateQueueManagedObjectContext.performBlockAndWait({ () -> Void in
                
                // get cached resource
                let (resource, error) = self.findOrCreateEntity(entity, withResourceID: resourceID, context: self.privateQueueManagedObjectContext)
                
                managedObject = resource
                
                if error != nil {
                    
                    completionBlock(error: error, managedObject: nil)
                    
                    return
                }
                
                // set values
                let setJSONError = self.setJSONObject(jsonObject!, forManagedObject: managedObject!, context: self.privateQueueManagedObjectContext)
                
                if setJSONError != nil {
                    
                    completionBlock(error: error, managedObject: nil)
                    
                    return
                }
                
                // set date cached
                self.didCacheManagedObject(resource!)
                
                // save
                
                let saveError = NSErrorPointer()
                
                if !self.privateQueueManagedObjectContext.save(saveError) {
                    
                    completionBlock(error: saveError.memory, managedObject: nil)
                    
                    return
                }
            })
            
            // get the corresponding managed object that belongs to the main queue context
            var mainContextManagedObject: NSManagedObject?
            
            self.managedObjectContext.performBlockAndWait({ () -> Void in
                
                mainContextManagedObject = self.managedObjectContext.objectWithID(managedObject!.objectID)
            })
            
            completionBlock(error: nil, managedObject: mainContextManagedObject)
        })
    }
    
    public func createEntity(name: String, withInitialValues initialValues: [String: AnyObject]?, URLSession: NSURLSession, completionBlock: ((error: NSError?, managedObject: NSManagedObject?) -> Void)) -> NSURLSessionDataTask {
        
        let entity = self.model.entitiesByName[name]! as NSEntityDescription
        
        var jsonValues: [String: AnyObject]?
        
        // convert initial values to JSON
        if initialValues != nil {
            
            jsonValues = entity.JSONObjectFromCoreDataValues(initialValues!, usingResourceIDAttributeName: self.resourceIDAttributeName)
        }
        
        return self.createResource(entity, withInitialValues: jsonValues, URLSession: URLSession, completionBlock: { (error, managedObject) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, managedObject: nil)
                
                return
            }
            
            
            
        })
    }
    
    // MARK: - Internal Methods
    
    private func mergeChangesFromContextDidSaveNotification(notification: NSNotification) {
        
        self.managedObjectContext.performBlock { () -> Void in
            
            self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    private func jsonWritingOption() -> NSJSONWritingOptions {
        
        if self.prettyPrintJSON {
            
            return NSJSONWritingOptions.PrettyPrinted;
        }
            
        else {
            
            return NSJSONWritingOptions.allZeros;
        }
    }
    
    private func resourcePathForEntity(entity: NSEntityDescription) -> String {
        
        return (self.entitiesByResourcePath as NSDictionary).allKeysForObject(entity).first as String
    }
    
    // MARK: API
    
    // The API private methods separate the JSON validation and HTTP requests from Core Data caching.
    
    /** Makes the actual search request to the server based on JSON input. */
    private func searchForResource(entity: NSEntityDescription, withParameters parameters:[String: AnyObject], URLSession: NSURLSession, completionBlock: ((error: NSError?, results: [[String: String]]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let resourcePath = self.resourcePathForEntity(entity)
        
        let searchURL = self.serverURL.URLByAppendingPathComponent(self.searchPath!).URLByAppendingPathComponent(resourcePath)
        
        let urlRequest = NSMutableURLRequest(URL: searchURL)
        
        urlRequest.HTTPMethod = "POST"
        
        // add JSON data
        
        let jsonData = NSJSONSerialization.dataWithJSONObject(parameters, options: self.jsonWritingOption(), error: nil)!
        
        urlRequest.HTTPBody = jsonData
        
        let dataTask = URLSession.dataTaskWithRequest(urlRequest, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, results: nil)
            }
            
            let httpResponse = response as NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.toRaw() {
                
                let errorCode = ErrorCode.fromRaw(httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(self) for Search Request"
                        let key = "ErrorCode.\(self).LocalizedDescription.Search"
                        
                        let customError = NSError(domain: NetworkObjectsErrorDomain, code: errorCode!.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle, value: "Permission to perform search is denied", comment: comment)])
                        
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
    
    private func createResource(entity: NSEntityDescription, withInitialValues initialValues: [String: AnyObject]?, URLSession: NSURLSession, completionBlock: ((error: NSError?, managedObject: NSManagedObject?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let resourcePath = self.resourcePathForEntity(entity)
        
        let createResourceURL = self.serverURL.URLByAppendingPathComponent(resourcePath)
        
        let request = NSMutableURLRequest(URL: createResourceURL)
        
        request.HTTPMethod = "POST"
        
        
        
    }
    
    private func getResource(entity: NSEntityDescription, withID resourceID: UInt, URLSession: NSURLSession, completionBlock: ((error: NSError?, resource: [String: AnyObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let resourcePath = self.resourcePathForEntity(entity)
        
        let getResourceURL = self.serverURL.URLByAppendingPathComponent(resourcePath).URLByAppendingPathComponent("\(resourceID)")
        
        let request = NSURLRequest(URL: getResourceURL)
        
        let dataTask = URLSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                
                completionBlock(error: error, resource: nil)
            }
            
            let httpResponse = response as NSHTTPURLResponse
            
            // error codes
            
            if httpResponse.statusCode != ServerStatusCode.OK.toRaw() {
                
                let errorCode = ErrorCode.fromRaw(httpResponse.statusCode)
                
                if errorCode != nil {
                    
                    if errorCode == ErrorCode.ServerStatusCodeForbidden {
                        
                        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
                        let tableName = "Error"
                        let comment = "Description for ErrorCode.\(self) for GET Request"
                        let key = "ErrorCode.\(self).LocalizedDescription.GET"
                        let value = "Access to resource is denied"
                        
                        let customError = NSError(domain: NetworkObjectsErrorDomain, code: errorCode!.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle, value: value, comment: comment)])
                        
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
            
            managedObject.setValue(NSDate.date(), forKey: self.dateCachedAttributeName!)
        }
    }
    
    private func findEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, context: NSManagedObjectContext) -> (NSManagedObjectID?, NSError?) {
        
        // get cached resource...
        
        let fetchRequest = NSFetchRequest(entityName: entity.name)
        
        fetchRequest.fetchLimit = 1
        
        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        
        // create predicate
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        // fetch
        
        let error = NSErrorPointer()
        
        let results = context.executeFetchRequest(fetchRequest, error: error) as? [NSManagedObjectID]
        
        // halt execution if error
        if error.memory != nil {
            
            return (nil, error.memory)
        }
        
        var objectID = results?.first
        
        return (objectID, nil)
    }
    
    private func findOrCreateEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, context: NSManagedObjectContext) -> (NSManagedObject?, NSError?) {
        
        // get cached resource...
        
        let fetchRequest = NSFetchRequest(entityName: entity.name)
        
        fetchRequest.fetchLimit = 1
        
        // create predicate
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        fetchRequest.returnsObjectsAsFaults = false
        
        // fetch
        
        let error = NSErrorPointer()
        
        let results = context.executeFetchRequest(fetchRequest, error: error) as? [NSManagedObject]
        
        // halt execution if error
        if error.memory != nil {
            
            return (nil, error.memory)
        }
        
        var resource = results?.first
        
        // create cached resource if not found
        
        if resource == nil {
            
            // create a new entity
            
            resource = NSEntityDescription.insertNewObjectForEntityForName(entity.name, inManagedObjectContext: context) as? NSManagedObject
            
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
                
                let destinationEntity = relationship!.destinationEntity
                
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

