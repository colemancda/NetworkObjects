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
    
    /// WebSocket-backed **NetworkObjects** server. 
    ///
    /// Recommended to use [websocketd](https://github.com/joewalnes/websocketd)
    public final class WebSocket: ServerType {
        
        // MARK: - Properties
        
        public var dataSource: ServerDataSource
        
        public var delegate: ServerDelegate?
        
        public var permissionsDelegate: ServerPermissionsDelegate?
        
        /// Function for logging purposes
        public var log: (String -> ())?
        
        public var respond: String -> () = { (output: String ) -> Void in
            
            // for websocketd
            print(output)
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


