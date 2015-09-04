//
//  RequestMessage.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/3/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation

public struct RequestMessage {
    
    public var request: Request
    
    public var metadata = JSONObject()
    
    public init(request: Request) {
        
        self.request = request
    }
}

private extension RequestMessage {
    
    enum Key: String {
        
        case Request
        
        case Metadata
    }
}

public extension RequestMessage {
    
    
}