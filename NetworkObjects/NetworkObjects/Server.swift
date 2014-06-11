//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/9/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

protocol ServerDelegate {
    
    func didEncounterInternalError(server: Server, error: NSError, requestType: Integer)
    
    
}

protocol ServerDataSource {
    
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

class Server {
    
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
       
        let urls: Dictionary;
        
        for
        
    }()
    
    init(store: ServerStore, delegate: AnyObject?, sslIdentityAndCertificates: NSArray?){
        
        self.store = store
        self.delegate = delegate
        self.sslIdentityAndCertificates = sslIdentityAndCertificates
        
    }
    
    func start(port: Integer){
        
        
    }
    
    func stop(){
        
        
    }
    
    
}
