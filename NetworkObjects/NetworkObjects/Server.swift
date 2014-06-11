//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/9/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation

protocol ServerDelegate {
    
    func didEncounterInternalError(server: Server, error: NSError, requestType: Integer)
    
    
}

class HTTPServer: RoutingHTTPServer {
    
    let server: Server
    
    init(server){
        self.server = server;
    }
    
}

class Server {
    
    let store: ServerStore
    
    let httpServer: HTTPServer
    
    let delegate: AnyObject?
    
    let sslIdentityAndCertificates: NSArray?
    
    var prettyPrintJSON: Bool = NO;
    
    init(store, delegate, sslIdentityAndCertificates){
        
        self.store = store
        self.delegate = delegate
        self.sslIdentityAndCertificates = sslIdentityAndCertificates
    }
    
    func start(port: Integer){
        
        
        
    }
    
    func stop(){
        
        
    }
    
    
}
