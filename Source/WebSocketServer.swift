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
    /// Recommended to use with [websocketd](https://github.com/joewalnes/websocketd)
    public final class WebSocket: ServerType {
        
        // MARK: - Properties
        
        public let model: [Entity]
        
        public var dataSource: ServerDataSource
        
        public var delegate: ServerDelegate?
        
        public var settings = Server.Settings()
        
        // MARK: - Initialization
        
        public init(model: [Entity],
            dataSource: ServerDataSource,
            delegate: ServerDelegate? = nil) {
                
                self.model = model
                self.dataSource = dataSource
                self.delegate = delegate
        }
        
        // MARK: - Methods
        
        /// Process string as input.
        public func input(input: String) -> String {
            
            guard let requestJSON = JSON.Value(string: input),
                let respuestMessage = RequestMessage(JSONValue: requestJSON, parameters: self.model)
                
                else {
                
                let response = Response.Error(StatusCode.BadRequest.rawValue)
                
                let responseMessage = ResponseMessage(response)
                
                let responseJSON = responseMessage.toJSON()
                
                return responseJSON.toString(JSONWritingOptions)!
            }
            
            /// Process method will handle the protocol-independent parsing
            let responseMessage = self.process(respuestMessage)
            
            let responseJSON = responseMessage.toJSON()
            
            return responseJSON.toString(JSONWritingOptions)!
        }
    }
}


