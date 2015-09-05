//
//  WebSocketServer.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/5/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public extension Server {
    
    public final class WebSocket: ServerType {
        
        // MARK: - Properties
        
        public var dataSource: ServerDataSource
        
        public var delegate: ServerDelegate?
        
        public var permissionsDelegate: ServerPermissionsDelegate?
        
        /// Function for logging purposes
        public var log: ((String) -> ())?
        
        /// Function for sending the WebSocket response
        public var sendMessage: String -> () = {
            
            // for websocketd
            print($0)
            fflush(__stdoutp)
        }
        
        // MARK: - Initialization
        
        public init(dataSource: ServerDataSource,
            delegate: ServerDelegate? = nil,
            permissionsDelegate: ServerPermissionsDelegate?) {
                
                self.dataSource = dataSource
                self.delegate = delegate
                self.permissionsDelegate = permissionsDelegate
        }
        
        // MARK: - Methods
        
        /// Process string as input.
        public func input(input: String) {
            
            
        }
    }
}


