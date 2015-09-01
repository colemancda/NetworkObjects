//
//  ServerRequest.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation

public extension Server {
    
    public struct Request: JSONConvertible {
        
        public var type: RequestType
        
        public var entity: String
        
        public var resourceID: String?
        
        public var metadata: JSONObject = JSONObject()
        
        public var values: JSONObject = JSONObject()
        
        public init() { }
    }
}