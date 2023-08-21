//
//  NetworkObjects.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation
import CoreModel

/// NetworkObjects Object Store. 
public protocol ObjectStore: AnyObject {
    
    func fetch<T: NetworkEntity>(_ type: T.Type, for id: T.ID) async throws -> T
    
    func create<T: NetworkEntity>(_ type: T.CreateView) async throws -> T
    
    func edit<T: NetworkEntity>(_ value: T.EditView, for id: T.ID) async throws -> T
    
    func delete<T: NetworkEntity>(_ type: T.Type, for id: T.ID) async throws
    
    func query<T: NetworkEntity>(_ request: QueryRequest<T>) async throws -> [T.ID]
}
