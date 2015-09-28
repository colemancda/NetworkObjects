//
//  Store.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public extension CoreModel.Store {
    
    /// Caches the values of a response.
    ///
    /// - Note: Request and Response must be of the same type or this method will do nothing.
    func cacheResponse(response: Response, forRequest request: Request, dateCachedAttributeName: String?) throws {
        
        switch (request, response) {
            
            // 404 responses
            
        case let (.Get(resource), .Error(errorStatusCode)):
            
            // delete object from cache if not found response
            
            if errorStatusCode == StatusCode.NotFound.rawValue {
                
                if try self.exists(resource) {
                    
                    try self.delete(resource)
                }
            }
            
        case let (.Edit(resource, _), .Error(errorStatusCode)):
            
            // delete object from cache if not found response
            
            if errorStatusCode == StatusCode.NotFound.rawValue {
                
                if try self.exists(resource) {
                    
                    try self.delete(resource)
                }
            }
            
        case let (.Delete(resource), .Error(errorStatusCode)):
            
            // delete object from cache if now found response
            
            if errorStatusCode == StatusCode.NotFound.rawValue {
                
                if try self.exists(resource) {
                    
                    try self.delete(resource)
                }
            }
            
            // standard responses
            
        case (.Get(let resource), .Get(var values)):
            
            try self.createCachePlaceholders(values, entityName: resource.entityName)
            
            // set cache date
            if let dateCachedAttributeName = dateCachedAttributeName {
                
                values[dateCachedAttributeName] = Value.Attribute(.Date(Date()))
            }
            
            // update values
            if try self.exists(resource) {
                
                try self.edit(resource, changes: values)
            }
                
            // create resource and set values
            else {
                
                try self.create(resource, initialValues: values)
            }
            
        case (let .Edit(resource, _), .Edit(var values)):
            
            try self.createCachePlaceholders(values, entityName: resource.entityName)
            
            // set cache date
            if let dateCachedAttributeName = dateCachedAttributeName {
                
                values[dateCachedAttributeName] = Value.Attribute(.Date(Date()))
            }
            
            // update values
            if try self.exists(resource) {
                
                try self.edit(resource, changes: values)
            }
                
            // create resource and set values
            else {
                
                try self.create(resource, initialValues: values)
            }
            
        case (let .Create(entityName, _), .Create(let resourceID, var values)):
            
            try self.createCachePlaceholders(values, entityName: entityName)
            
            // set cache date
            if let dateCachedAttributeName = dateCachedAttributeName {
                
                values[dateCachedAttributeName] = Value.Attribute(.Date(Date()))
            }
            
            let resource = Resource(entityName, resourceID)
            
            try self.create(resource, initialValues: values)
            
        case let (.Delete(resource), .Delete):
            
            if try self.exists(resource) {
                
                try self.delete(resource)
            }
            
        case let (.Search(fetchRequest), .Search(resourceIDs)):
            
            for resourceID in resourceIDs {
                
                let resource = Resource(fetchRequest.entityName, resourceID)
                
                // create placeholder resources for results
                if try self.exists(resource) == false {
                    
                    try self.create(resource, initialValues: ValuesObject())
                }
            }
            
        default: break
        }
    }
}

private extension CoreModel.Store {
    
    /// Resolves relationships in the values and creates placeholder resources.
    private func createCachePlaceholders(values: ValuesObject, entityName: String) throws {
        
        guard let entity = self.model[entityName] else { throw StoreError.InvalidEntity }
        
        for (key, value) in values {
            
            switch value {
                
            case let .Relationship(relationshipValue):
                
                guard let relationship = entity.relationships[key] else { throw StoreError.InvalidValues }
                
                switch relationshipValue {
                    
                case let .ToOne(resourceID):
                    
                    let resource = Resource(relationship.destinationEntityName, resourceID)
                    
                    if try self.exists(resource) == false {
                        
                        try self.create(resource, initialValues: ValuesObject())
                    }
                    
                case let .ToMany(resourceIDs):
                    
                    for resourceID in resourceIDs {
                        
                        let resource = Resource(relationship.destinationEntityName, resourceID)
                        
                        if try self.exists(resource) == false {
                            
                            try self.create(resource, initialValues: ValuesObject())
                        }
                    }
                }
                
            default: break
            }
        }
    }
}


