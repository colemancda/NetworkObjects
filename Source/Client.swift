//
//  Client.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Namespace struct for **NetworkObjects** client classes:
///
///  - NetworkObjects.Client.HTTP
///  - NetworkObjects.Client.WebSocket
public struct Client { }

/// Connects to the **NetworkObjects** server.
public protocol ClientType: class {
    
    /// The URL of the **NetworkObjects** server that this client will connect to.
    var serverURL: String { get }
    
    var model: Model { get }
    
    var requestTimeout: TimeInterval { get set }
    
    var JSONOptions: [JSON.Serialization.WritingOption] { get set }
    
    var metadataForRequest: ((request: Request) -> [String: String])? { get set }
    
    var didReceiveMetadata: ((metadata: [String: String]) -> Void)? { get set }
    
    /// Sends the request and parses the response.
    func send(request: Request) throws -> Response
}



