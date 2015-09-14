//
//  Store.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Class requests and caches responses from the server.
public final class Store<Client: ClientType, CacheStore: CoreModel.Store> {
    
    // MARK: - Properties
    
    public let client: Client
    
    public let cacheStore: CacheStore
    
    // MARK: - Initialization
    
    public init?(client: Client, cacheStore: CacheStore) {
        
        self.client = client
        self.cacheStore = cacheStore
        
        guard client.model == cacheStore.model else { return nil }
    }
    
    // MARK: - Methods
    
    
    
    // MARK: - Private Methods
    
    
}