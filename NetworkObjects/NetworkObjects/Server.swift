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
    
    // Search
    func canPerformSearchForServer(server: Server, request: RouteRequest, entity: NSEntityDescription) -> Bool
    func didPerformSearchForServer(server: Server, request: RouteRequest, entity: NSEntityDescription)
}

@objc protocol ServerDataSource {
    
    func managedObjectContextForServer(server: Server, request: RouteRequest) -> NSManagedObjectContext
    func resourceIDForNewResourceInstanceForServer(server: Server, entity: NSEntityDescription) -> NSInteger
    func resourceIDKeyForServer(server: Server, entity: NSEntityDescription) -> NSString
    
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
    
    // Lazy Properties
    
    @lazy var httpServer: HTTPServer = {
        
        // create and configure HTTP server
       
        let httpServer = HTTPServer(server: self);
        
        // add resource global handlers
        
        for (path, entity) in self.resourcePaths {
            
            // add search path
            
            if self.searchPath {
                
                let searchPathExpression = "/" + self.searchPath! + "/" + path
                
                let block: (RouteRequest?, RouteResponse?) -> Void = {
                    
                    request, response in self.handleSearch(request!, entity: entity, response: response!)
                }
                
                httpServer.post(searchPathExpression, withBlock:block)
            }
            
            // create new resource
            
            let newInstancePathExpression = "/" + path
            
            let block: (RouteRequest?, RouteResponse?) -> Void = {
                
                request, response in self.handleCreateNewInstance(request!, entity: entity, response: response!)
            }
            
            httpServer.post(newInstancePathExpression, withBlock:block)
            
        }
        
        return httpServer
        
    }()
    
    @lazy var resourcePaths: Dictionary<String, NSEntityDescription> = {
        
        var urls = Dictionary<String, NSEntityDescription>();
        
        for object: AnyObject in self.managedObjectModel.entities {
            
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
    
    // handler functions
    
    func handleSearch(request: RouteRequest, entity: NSEntityDescription, response: RouteResponse) {
        
        let delegate = self.delegate as ServerDelegate
        
        if !delegate.canPerformSearchForServer(self, request: request, entity: entity) {
            
            response.statusCode = 400;
        }
        
    }
    
    func handleCreateNewInstance(request: RouteRequest, entity: NSEntityDescription, response: RouteResponse) {
        
    }
    
}
