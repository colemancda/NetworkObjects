//
//  ResponseMessage.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/2/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public struct ResponseMessage {
    
    public var status: Bool
    
    public var metadata = JSONObject()
    
    public var response: Response
}

private extension RequestMessage {
    
    enum Key: String {
        
        case Status
        
        case Metadata
        
        case Values
    }
}