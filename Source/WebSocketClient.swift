//
//  WebSocketClient.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/5/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel
import SwiftWebSocket

public extension Client {
    
    @available(OSX 10.10, iOS 8.0, *)
    public final class WebSocket: ClientType {
        
        // MARK: - Properties
        
        /// The URL of the **NetworkObjects** server that this client will connect to.
        public let serverURL: String
        
        public let model: [Entity]
        
        public var JSONOptions: [JSON.Serialization.WritingOption] = [.Pretty]
        
        // MARK: Callbacks
        
        public var didOpen: (() -> ())?
        
        public var didClose: (() -> ())?
        
        public var metadataForRequest: ((request: Request) -> [String: String])?
        
        public var didReceiveMetadata: ((metadata: [String: String]) -> Void)?
        
        public var cacheStores = [Store]()
        
        // MARK: - Private Properties
        
        private var websocket: InternalWebSocket!
        
        /// Serial queue for thread safety
        private var operationQueue = dispatch_queue_create("NetworkObjects.Client Queue", nil)
        
        // MARK: - Initialization
        
        public init(serverURL: String, model: [Entity]) {
            
            self.serverURL = serverURL
            self.model = model
        }
        
        // MARK: - Methods
        
        /// Initiates the WebSocket connection to the server.
        public func connect() throws {
            
            try sync { () throws -> Void in
                
                let semaphore = dispatch_semaphore_create(0)
                
                var error: ErrorType?
                
                if let websocket = self.websocket {
                    
                    websocket.close()
                }
                
                self.websocket = SwiftWebSocket.WebSocket(self.serverURL)
                
                self.websocket.event.open = {
                    
                    dispatch_semaphore_signal(semaphore)
                }
                
                self.websocket.event.error = { (websocketError: ErrorType) in
                    
                    error = websocketError
                    
                    dispatch_semaphore_signal(semaphore)
                }
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                
                guard error == nil else { throw error! }
            }
        }
        
        /// Closes the WebSocket connection to the server.
        public func disconnect() {
            
            sync { () -> Void in
                
                self.websocket?.close()
            }
        }
                
        /// Sends the request and parses the response.
        public func send(request: Request, timeout: TimeInterval = 30) throws -> Response {
            
            var response: Response!
            
            try sync { () throws -> Void in
                
                // check that requested entity belongs to model
                guard let entity: Entity = {
                    for entity in self.model { if entity.name == request.entityName { return entity } }
                    return nil
                    
                }() as Entity? else { throw Error.InvalidRequest }
                
                let metadata = self.metadataForRequest?(request: request) ?? [String: String]()
                
                let requestMessage = RequestMessage(request, metadata: metadata)
                
                let json = requestMessage.toJSON()
                
                guard let jsonString = json.toString(self.JSONOptions)
                    else { fatalError("Could not generate JSON for \(json)") }
                
                let responseString = try self.websocket.sendRequest(jsonString, timeout: timeout)
                
                // parse response
                
                guard let responseJSON = JSON.Value(string: responseString),
                    let responseMessage = ResponseMessage(JSONValue: responseJSON, parameters:(request.type, entity))
                    else { throw Error.InvalidResponse }
                
                self.didReceiveMetadata?(metadata: responseMessage.metadata)
                
                response = responseMessage.response
            }
            
            return response
        }
        
        // MARK: - Private Methods
        
        /// Perform an action in a thread safe manner
        private func sync(block: () throws -> Void) throws {
            
            var thrownError: ErrorType?
            
            dispatch_sync(operationQueue) { () -> Void in
                
                do { try block() }
                catch { thrownError = error }
            }
            
            guard thrownError == nil else { throw thrownError! }
        }
        
        /// Perform an action in a thread safe manner
        private func sync(block: () -> Void) {
            
            dispatch_sync(operationQueue) { () -> Void in block() }
        }
    }
}
