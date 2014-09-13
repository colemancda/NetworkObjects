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

public class Server {
    
    public let dataSource: AnyObject
    
    public let delegate: AnyObject
    
    public let searchPath: String
    
    public let prettyPrintJSON: Bool
    
    public let resourceIDAttributeName: String
    
    public let sslIdentityAndCertificates: [AnyObject]
    
    public let managedObjectModel: NSManagedObjectModel
    
    internal func initEntitiesByResourcePath() -> Dictionary<String, NSEntityDescription> {
        
        var entitiesByResourcePath: Dictionary<String, NSEntityDescription>;
        
        var entities = managedObjectModel.entities as [NSEntityDescription];
        
        for entity in entities {
            
            if !entity.abstract {
                
                
            }
        }
        
    }
    
    public let entitiesByResourcePath: Dictionary<String, NSEntityDescription> = initEntitiesByResourcePath();
    
    public init(dataSource: AnyObject, delegate: AnyObject?, managedObjectModel: NSManagedObjectModel, searchPath:String?, resourceIDAttributeName:String, prettyPrintJSON:Bool, sslIdentityAndCertificates: [AnyObject]) {
        
        // set values
        self.dataSource = dataSource;
        self.managedObjectModel = managedObjectModel;
        self.resourceIDAttributeName = resourceIDAttributeName;
        self.sslIdentityAndCertificates = sslIdentityAndCertificates;
        
        // optional values
        if (delegate != nil) {
            self.delegate = delegate!;
        }
        if (searchPath  != nil){
            self.searchPath = searchPath!;
        }
    }
    
}

protocol ServerDelegate {
    
    func server(Server, didEncounterInternalError error: NSError, forRequest request: ServerRequest, userInfo: Dictionary<String, AnyObject>)
    
}

protocol ServerDataSource {
    
}

class ServerRequest {
    
    
    
}
