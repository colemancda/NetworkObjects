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
        
        self.privateQueueManagedObjectContext.undoManager = nil
        self.privateQueueManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        // listen for notifications (for merging changes)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesFromContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueManagedObjectContext)
    }
    
    // MARK: - Requests
    
    
    
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
    
    // MARK: Convert
    
    // MARK: Errors
    
    // MARK: Cache
    
}

