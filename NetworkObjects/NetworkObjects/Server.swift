//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/9/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

@objc protocol ServerDelegate {
    
    func didEncounterInternalError(server: Server, error: NSError, requestType: NSInteger)
    
    
}

@objc protocol ServerDataSource {
    
    func resourceIDForNewResourceInstance(server: Server, entity: NSEntityDescription) -> Int
    func managedObjectContextForRequest
}

class HTTPServer: RoutingHTTPServer {
    
    let server: Server
    
    init(server: Server){
        self.server = server;
    }
    
}

class ServerConnection: RoutingConnection {
    
    
}

@objc class Server {
    
    // Server constants
    
    let dataSource: AnyObject
    
    let delegate: AnyObject?
    
    let managedObjectModel: NSManagedObjectModel
    
    let sslIdentityAndCertificates: NSArray?
    
    let prettyPrintJSON: Bool
    
    let searchPath: String?
    
    let includeModelVersion: Bool
    
    // Lazy Properties
    
    @lazy var httpServer: HTTPServer = {
        
        // create and configure HTTP server
       
        let httpServer = HTTPServer(server: self);
        
        // add resource instances handlers
        
        for (path, entity) in self.resourcePaths {
            
            // add search path
            
            if self.searchPath {
                
                let searchPathExpression = "/" + self.searchPath! + "/" + path
                
                let block: (RouteRequest?, RouteResponse?) -> Void = {
                    
                    request, response in
                    
                    
                    
                }
                
                httpServer.post(searchPathExpression, withBlock:block)
            }
            
        }
        
        return httpServer
        
    }()
    
    @lazy var resourcePaths: Dictionary<String, NSEntityDescription> = {
        
        var urls = Dictionary<String, NSEntityDescription>();

        let dataSource = self.dataSource as ServerDataSource
        
        let model = self.dataSource.managedObjectModel(forServer: self)
        
        for object: AnyObject in model.entities {
            
            if let entity = object as? NSEntityDescription {
                
                // make sure the entity is not abstract
                
                if !entity.abstract {
                    
                    let entityName: String = entity.name
                    
                    urls[entityName] = entity
                }
            }
        }
        
        return urls
        
    }()
    
    init(dataSource: AnyObject, delegate: AnyObject?, managedObjectModel: NSManagedObjectModel, sslIdentityAndCertificates: NSArray?, prettyPrintJSON: Bool, searchPath: String?){
        
        self.dataSource = dataSource
        self.delegate = delegate
        self.sslIdentityAndCertificates = sslIdentityAndCertificates
        self.prettyPrintJSON = prettyPrintJSON
        self.managedObjectModel = managedObjectModel
        self.searchPath = searchPath
        
    }
    
    func start(port: Int){
        
        
    }
    
    func stop(){
        
        
    }
    
    
}
