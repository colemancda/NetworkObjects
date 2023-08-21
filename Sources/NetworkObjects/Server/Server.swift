//
//  Server.swift
//  
//
//  Created by Alsey Coleman Miller on 8/18/23.
//

import Foundation
import CoreModel

public protocol NetworkObjectsServer {
        
    associatedtype Request
    
    associatedtype Response
        
    //func register<T>(_ controller: T) where T: Controller
}

public protocol NetworkEntityController {
    
    associatedtype Entity: NetworkEntity
    
    associatedtype Database: ModelStorage
    
    associatedtype Server: NetworkObjectsServer
    
    var database: Database { get }
            
    func fetch(_ id: Entity.ID, request: Server.Request) async throws -> Entity?
    
    func create(_ create: Entity.CreateView, request: Server.Request) async throws -> Entity
    
    func edit(_ edit: Entity.EditView, for id: Entity.ID, request: Server.Request) async throws -> Entity
    
    func delete(_ id: Entity.ID, request: Server.Request) async throws -> Bool
}

public extension NetworkEntityController {
    
    func fetch(_ id: Entity.ID, request: Server.Request) async throws -> Entity? {
        try await database.fetch(Entity.self, for: id)
    }
    
    func delete(_ id: Entity.ID, request: Server.Request) async throws -> Bool {
        // check if exists
        let count = try await database.count(Entity.self)
        guard count > 0 else {
            return false
        }
        assert(count == 1)
        // delete instance
        try await database.delete(Entity.self, for: id)
        return true
    }
}
