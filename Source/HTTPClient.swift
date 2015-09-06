//
//  HTTPClient.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/5/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public extension Client {
    
    public final class HTTP: ClientType {
        
        // MARK: - Properties
        
        /// The URL of the **NetworkObjects** server that this client will connect to.
        public let serverURL: String
        
        public let model: [Entity]
        
        public let HTTPClient: SwiftFoundation.HTTP.Client
        
        /// Function for logging purposes.
        public var log: ((message: String) -> ())?
        
        public var metadata: ((request: Request) -> [String: String])?
        
        public var didFetch: ((resource: Resource, values: ValuesObject) -> Void)?
        
        // MARK: - Initialization
        
        public init(serverURL: String, model: [Entity], HTTPClient: SwiftFoundation.HTTP.Client) {
            
            self.serverURL = serverURL
            self.model = model
            self.HTTPClient = HTTPClient
        }
        
        // MARK: - Methods
        
        /// Sends the request and parses the response.
        public func send(request: Request, timeout: TimeInterval = 30) throws -> Response {
            
            // check that requested entity belongs to model
            guard let entity: Entity = {
                for entity in self.model { if entity.name == request.entityName { return entity } }
                return nil
            }() as Entity? else { throw Error.InvalidRequest }
            
            var metadata = [String: String]()
            
            if let metadataHandler = self.metadata {
                
                metadata = metadataHandler(request: request)
            }
            
            var response: Response!
            
            let requestMessage = RequestMessage(request, metadata: metadata)
            
            let json = requestMessage.toJSON()
            
            guard let jsonString = json.toString()
                else { fatalError("Could not generate JSON for \(json)") }
            
            let responseString = try self.websocket.sendRequest(jsonString, timeout: timeout)
            
            // parse response
            
            guard let responseJSON = JSON.Value(string: responseString),
                let responseMessage = ResponseMessage(JSONValue: responseJSON, parameters:(request.type, entity))
                else { throw Error.InvalidResponse }
            
            return response
        }
    }
}