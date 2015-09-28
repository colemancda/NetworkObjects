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
        
        public let model: Model
        
        public let HTTPClient: SwiftFoundation.HTTP.Client
        
        public var JSONOptions: [JSON.Serialization.WritingOption] = [.Pretty]
        
        public var requestTimeout: TimeInterval = 30
        
        // MARK: Callbacks
        
        public var willSendRequest: (Request -> [String: String])?
        
        public var didRecieveResponse: (ResponseMessage -> Void)?
        
        // MARK: - Initialization
        
        public init(serverURL: String, model: Model, HTTPClient: SwiftFoundation.HTTP.Client) {
            
            self.serverURL = serverURL
            self.model = model
            self.HTTPClient = HTTPClient
        }
        
        // MARK: - Methods
        
        /// Sends the request and parses the response.
        public func send(request: Request) throws -> Response {
            
            // check that requested entity belongs to model
            guard let entity = self.model[request.entityName] else { throw Error.InvalidRequest }
            
            let metadata = self.willSendRequest?(request) ?? [String: String]()
            
            let requestMessage = RequestMessage(request, metadata: metadata)
            
            let httpRequest = requestMessage.toHTTPRequest(self.serverURL, timeout: self.requestTimeout, options: self.JSONOptions)
            
            let httpResponse: SwiftFoundation.HTTP.Response = try self.HTTPClient.sendRequest(httpRequest)
            
            // try to parse response
            
            guard let responseMessage = ResponseMessage(HTTPResponse: httpResponse, parameters: (request.type, entity)) else { throw Error.InvalidResponse }
            
            self.didRecieveResponse?(responseMessage)
            
            return responseMessage.response
        }
    }
}

