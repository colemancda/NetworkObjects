//
//  Error.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

public enum NetworkObjectsError: Error {
    
    case authenticationRequired
    case invalidStatusCode(Int)
    case invalidResponse(Data)
}
