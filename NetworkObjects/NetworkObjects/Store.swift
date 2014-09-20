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
    public func performSearch(fetchRequest: NSFetchRequest, URLSession: NSURLSession, completionBlock: ((error: NSError?, results: [NSManagedObject]?) -> Void)) -> NSURLSessionDataTask {
        
        // build JSON request from fetch request
        
        var jsonObject = [String: AnyObject]()
        
        // optional comparison predicate
        
        let predicate = fetchRequest.predicate as? NSComparisonPredicate
        
        if predicate != nil && predicate?.predicateOperatorType != NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            jsonObject[SearchParameter.PredicateKey.toRaw()] = predicate?.leftExpression.keyPath
            
            // convert from Core Data to JSON
            let jsonValue: AnyObject? = fetchRequest.entity.JSONObjectFromCoreDataValues([predicate!.leftExpression.keyPath: predicate!.rightExpression.constantValue]).values.first
            
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
    
    // MARK: API
    
    /** Makes the actual search request to the server based on JSON input. */
    private func searchForResource(entity: NSEntityDescription, withParameters parameters:[String: AnyObject], URLSession: NSURLSession, completionBlock: ((error: NSError?, results: [[String: UInt]]?) -> Void)) -> NSURLSessionDataTask {
        
        // build URL
        
        let resourcePath = (self.entitiesByResourcePath as NSDictionary).allKeysForObject(entity).first as? String
        
        let searchURL = self.serverURL.URLByAppendingPathComponent(self.searchPath!).URLByAppendingPathComponent(resourcePath!)
        
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
                
                completionBlock(error: ErrorCode.InvalidServerResponse.toError(), results: nil)
                
                return
            }
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    // MARK: Convert
    
    
    
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
    
}

// MARK: - Extensions

private extension NSEntityDescription {
    
    func JSONObjectFromCoreDataValues(values: [String: AnyObject]) -> [String: AnyObject] {
        
        var jsonObject = [String: AnyObject]()
        
        return jsonObject
    }
}

