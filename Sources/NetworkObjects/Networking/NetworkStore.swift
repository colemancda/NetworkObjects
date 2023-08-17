//
//  NetworkStore.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class NetworkStore <Client: URLClient> : ObjectStore {
    
    // MARK: - Properties
    
    public let server: URL
    
    public let client: URLClient
    
    public var encoder: JSONEncoder
    
    public var decoder: JSONDecoder
    
    // MARK: - Initialization
    
    public init(
        server: URL,
        client: URLClient,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.server = server
        self.client = client
        self.encoder = encoder
        self.decoder = decoder
    }
    
    // MARK: - Methods
    
    public func fetch<T: Entity>(_ type: T.Type, for id: T.ID) async throws -> T {
        try await client.fetch(type, for: id, server: server, decoder: decoder)
    }
    
    public func create<T: Entity>(_ type: T.CreateView) async throws -> T {
        try await client.create(type, server: server, encoder: encoder, decoder: decoder)
    }
    
    public func edit<T: Entity>(_ value: T.EditView, for id: T.ID) async throws -> T {
        try await client.edit(value, for: id, server: server, encoder: encoder, decoder: decoder)
    }
    
    public func delete<T: Entity>(_ type: T.Type, for id: T.ID) async throws {
        try await client.delete(type, for: id, server: server)
    }
}
