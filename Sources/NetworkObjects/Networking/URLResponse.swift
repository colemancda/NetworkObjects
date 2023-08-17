//
//  URLResponse.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

internal extension URLClient {
    
    func response<Request, Response>(
        _ response: Response.Type,
        for request: Request,
        server: URL,
        decoder: JSONDecoder,
        authorization authorizationToken: AuthorizationToken? = nil,
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) async throws -> Response where Request: URLRequestConvertible, Response: Decodable {
        var headers = headers
        headers["accept"] = "application/json"
        let data = try await self.request(
            request,
            server: server,
            authorization: authorizationToken,
            statusCode: statusCode,
            headers: headers
        )
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            #if DEBUG
            throw error
            #else
            throw NetworkObjectsError.invalidResponse(data)
            #endif
        }
    }
    
    func response<Request, Response>(
        _ response: Response.Type,
        for request: Request,
        server: URL,
        encoder: JSONEncoder,
        decoder: JSONDecoder,
        authorization authorizationToken: AuthorizationToken? = nil,
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) async throws -> Response where Request: EncodableURLRequest, Response: Decodable {
        var headers = headers
        headers["accept"] = "application/json"
        let data = try await self.request(
            request,
            server: server,
            authorization: authorizationToken,
            statusCode: statusCode,
            headers: headers
        )
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            #if DEBUG
            throw error
            #else
            throw NetworkObjectsError.invalidResponse(data)
            #endif
        }
    }
}
