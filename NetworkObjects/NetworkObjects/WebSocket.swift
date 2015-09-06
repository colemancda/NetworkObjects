//
//  WebSocket.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/5/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import SwiftWebSocket

internal typealias InternalWebSocket = SwiftWebSocket.WebSocket

internal extension InternalWebSocket {
    
    /// Sends a message asyncronously
    func sendRequest(message: String, timeout: TimeInterval) throws -> String {
        
        // wait for response
        
        let semaphore = dispatch_semaphore_create(0)
        
        var error: ErrorType?
        
        var responseMessage: String!
        
        self.event.error = { (websocketError: ErrorType) in
            
            error = websocketError
            
            dispatch_semaphore_signal(semaphore)
        }
        
        self.event.message = { (data: Any) in
            
            responseMessage = data as! String
            
            dispatch_semaphore_signal(semaphore)
        }
        
        // send response and wait
        self.send(message)
        
        let waitTime = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout))
        
        guard dispatch_semaphore_wait(semaphore, waitTime) == 0
            else { throw WebSocketError.Timeout }
        
        guard error == nil else { throw error! }
        
        return responseMessage
    }
}

public enum WebSocketError: ErrorType {
    
    /// The request timed out
    case Timeout
}
