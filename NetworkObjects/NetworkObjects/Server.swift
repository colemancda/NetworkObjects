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
    
    func managedObjectModel(forServer server: Server) -> NSManagedObjectModel
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
    
    let sslIdentityAndCertificates: NSArray?
    
    // Server Variables
    
    var prettyPrintJSON: Bool = false;
    
    // Lazy Properties
    
    @lazy var httpServer: HTTPServer = {
       
        let httpServer = HTTPServer(server: self);
        
        return httpServer
        
    }()
    
    @lazy var resourcePaths: Dictionary<String, NSEntityDescription> = {
        
        // Could use model.entitiesByName
       
        var urls = Dictionary<String, NSEntityDescription>();
        
        let dataSource = self.dataSource as? ServerDataSource
        
        let model = self.dataSource.managedObjectModel(forServer: self)
        
        for object: AnyObject in model.entities {
            
            if let entity = object as? NSEntityDescription {
                
                let entityName: String = entity.name
                
                urls[entityName] = entity
            }
            
        }
        
        return urls
        
    }()
    
    init(dataSource: AnyObject, delegate: AnyObject?, sslIdentityAndCertificates: NSArray?){
        
        self.dataSource = dataSource
        self.delegate = delegate
        self.sslIdentityAndCertificates = sslIdentityAndCertificates
        
    }
    
    func start(port: Integer){
        
        
    }
    
    func stop(){
        
        
    }
    
    
}
