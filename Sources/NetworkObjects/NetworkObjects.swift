//
//  NetworkObjects.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// NetworkObjects Object Store. Can be local or remote DB.
public protocol ObjectStore: AnyObject {
    
    func fetch<T: Entity>(_ type: T.Type, for id: T.ID) async throws -> T
    
    func create<T: Entity>(_ type: T.CreateView) async throws -> T
    
    func edit<T: Entity>(_ value: T.EditView, for id: T.ID) async throws -> T
    
    func delete<T: Entity>(_ type: T.Type, for id: T.ID) async throws
}
