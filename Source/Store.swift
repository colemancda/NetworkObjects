//
//  Store.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Connects to the **NetworkObjects** server and caches data.
public final class Store {
    
    // MARK: - Properties
    
    /// The URL of the **NetworkObjects** server that this client will connect to.
    public let serverURL: String
    
    /// The **CoreModel** store what will be used to cache the returned data from the server.
    public let cacheStore: CoreModel.Store
    
    /// The name of a date attribute that will be used to indicate when an entity was fetched from the server. */
    public let dateCachedAttributeName: String?
    
    // MARK: - Initialization
    
    public init(serverURL: String, cacheStore: CoreModel.Store, dateCachedAttributeName: String? = nil) {
        
        self.serverURL = serverURL
        self.cacheStore = cacheStore
    }
    
    // MARK: - Methods
    
    
}
