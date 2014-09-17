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
    
    /** The path that the NetworkObjects server uses for search requests. If not specified then */
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
    
    init(persistentStoreCoordinator: NSPersistentStoreCoordinator, managedObjectContextConcurrencyType: NSManagedObjectContextConcurrencyType, serverURL: NSURL, entitiesByResourcePath: [String: NSEntityDescription], prettyPrintJSON: Bool, resourceIDAttributeName: String, dateCachedAttributeName: String?, searchPath: String?) {
        
        // set values
        
        
        
        // setup contexts
    }
    
    
}

