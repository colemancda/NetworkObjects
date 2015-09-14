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
        
        public var JSONOptions: [JSON.Serialization.WritingOption] = [.Pretty]
        
        public var requestTimeout: TimeInterval = 30
        
        // MARK: Callbacks
        
        public var metadataForRequest: ((request: Request) -> [String: String])?
        
        public var didReceiveMetadata: ((metadata: [String: String]) -> Void)?
                
        // MARK: - Initialization
        
        public init(serverURL: String, model: [Entity], HTTPClient: SwiftFoundation.HTTP.Client) {
            
            self.serverURL = serverURL
            self.model = model
            self.HTTPClient = HTTPClient
        }
        
        // MARK: - Methods
        
        /// Sends the request and parses the response.
        public func send(request: Request) throws -> Response {
            
            // check that requested entity belongs to model
            guard let entity: Entity = {
                for entity in self.model { if entity.name == request.entityName { return entity } }
                return nil
            }() as Entity? else { throw Error.InvalidRequest }
            
            let metadata = self.metadataForRequest?(request: request) ?? [String: String]()
            
            let requestMessage = RequestMessage(request, metadata: metadata)
            
            let httpRequest = requestMessage.toHTTPRequest(self.serverURL, timeout: self.requestTimeout, options: self.JSONOptions)
            
            let httpResponse: SwiftFoundation.HTTP.Response = try self.HTTPClient.sendRequest(httpRequest)
            
            // try to parse response
            
            guard let responseMessage = ResponseMessage(HTTPResponse: httpResponse, parameters: (request.type, entity)) else { throw Error.InvalidResponse }
            
            self.didReceiveMetadata?(metadata: responseMessage.metadata)
            
            return responseMessage.response
        }
    }
}

