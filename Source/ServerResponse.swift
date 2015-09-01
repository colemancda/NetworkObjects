//
//  ServerResponse.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation

public extension Server {
    
    public struct Response: JSONConvertible {
        
        public var status: Bool = true
        
        public var metadata: JSONObject = JSONObject()
        
        public var values: JSONObject = JSONObject()
        
        public init() { }
    }
}