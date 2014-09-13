//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/10/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// Constants

public let ServerFetchRequestKey: String = "NetworkObjects.ServerFetchRequestKey"

public let ServerResourceIDKey: String = "NetworkObjects.ServerResourceIDKey"

public let ServerManagedObjectKey: String = "NetworkObjects.ServerManagedObjectKey"

public let ServerManagedObjectContextKey: String = "NetworkObjects.ServerManagedObjectContextKey"

public let ServerNewValuesKey: String = "NetworkObjects.ServerNewValuesKey"

public let ServerFunctionNameKey: String = "NetworkObjects.ServerFunctionNameKey"

public let ServerFunctionJSONInputKey: String = "NetworkObjects.ServerFunctionJSONInputKey"

public let ServerFunctionJSONOutputKey: String = "NetworkObjects.ServerFunctionJSONOutputKey"

/** The class that will accept incoming connections 
*/

public class Server {
    
    // MARK: Properties
    
    /** The server's data source. */
    public let dataSource: ServerDataSource
    
    /** The server's delegate. */
    public let delegate: ServerDelegate
    
    /** The string that will be used to generate a URL for search requests. 
    NOTE Must not conflict with the resourcePath of entities.*/
    public let searchPath: String = "search"
    
    /** Determines whether the exported JSON should have whitespace for easier readability. */
    public let prettyPrintJSON: Bool = false
    
    /** The name of the Integer attribute that will be used for identifying instances of entities. */
    public let resourceIDAttributeName: String = "resourceID"
    
    /** To enable HTTPS for all incoming connections set this value to an array appropriate for use in kCFStreamSSLCertificates SSL Settings. It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.  */
    public let sslIdentityAndCertificates: [AnyObject]
    
    /** The managed object model */
    public let managedObjectModel: NSManagedObjectModel
    
    /** Resource path strings mapped to entity descriptions. */
    public lazy var entitiesByResourcePath: [String: NSEntityDescription] = initEntitiesByResourcePath();
    
    // MARK: Initialization
    
    /**  */
    public init(dataSource: ServerDataSource, delegate: ServerDelegate?, managedObjectModel: NSManagedObjectModel, searchPath:String?, resourceIDAttributeName:String, prettyPrintJSON:Bool, sslIdentityAndCertificates: [AnyObject]) {
        
        // set values
        self.dataSource = dataSource;
        self.managedObjectModel = managedObjectModel;
        self.resourceIDAttributeName = resourceIDAttributeName;
        self.sslIdentityAndCertificates = sslIdentityAndCertificates;
        
        // optional values
        if (delegate? != nil) {
            self.delegate = delegate!;
        }
        if (searchPath?  != nil){
            self.searchPath = searchPath!;
        }
    }
    
    /**  */
    private func initEntitiesByResourcePath() -> [String: NSEntityDescription] {
        
        var entitiesByResourcePathDictionary: [String: NSEntityDescription];
        
        var entities = managedObjectModel.entities as [NSEntityDescription];
        
        for entity in entities {
            
            if !entity.abstract {
                
                let path = self.dataSource.server(self, resourcePathForEntity: entity);
                
                entitiesByResourcePathDictionary[path] = entity
            }
        }
        
        return entitiesByResourcePathDictionary
    }
}

/**  */
public protocol ServerDataSource: class {
    
    func server(Server, managedObjectContextForRequest request: ServerRequest) -> NSManagedObjectContext
    
    func server(Server, newResourceIDForEntity entity: NSEntityDescription) -> Int
    
    func server(Server, resourcePathForEntity entity: NSEntityDescription) -> String;
    
    func server(Server, functionsForEntity entity: NSEntityDescription) -> [String]
}

/**  */
public protocol ServerDelegate: class {
    
    func server(Server, didEncounterInternalError error: NSError, forRequest request: ServerRequest, userInfo: Dictionary<String, AnyObject>)
    
    
}

public class ServerRequest {
    
    
    
}
