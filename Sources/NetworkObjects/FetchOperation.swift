//
//  FetchOperation.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

public enum FetchOperation <T: Entity> {
    
    case fetch(T.Type, T.ID)
    case create(T.Type)
    case edit(T.Type, T.ID)
    case delete(T.Type, T.ID)
}
