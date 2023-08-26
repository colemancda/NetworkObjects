//
//  URLRequest.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol URLRequestConvertible {
    
    static var method: HTTPMethod { get }
        
    static var contentType: String? { get }
        
    func url(for server: URL) -> URL
}

public protocol EncodableURLRequest: URLRequestConvertible {
    
    associatedtype Body: Encodable
    
    var content: Body { get }
}

public extension URLRequestConvertible {
    
    static var method: HTTPMethod { .get }
    
    static var contentType: String? { "application/json" }
}

public extension URLRequest {
    
    init<T: URLRequestConvertible>(
        request: T,
        server: URL
    ) {
        self.init(url: request.url(for: server))
        self.httpMethod = T.method.rawValue
        if let contentType = T.contentType {
            self.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
    }
    
    init<T: EncodableURLRequest>(
        request: T,
        server: URL,
        encoder: JSONEncoder
    ) throws {
        self.init(request: request, server: server)
        self.httpBody = try encoder.encode(request.content)
    }
}

internal extension URLClient {
    
    @discardableResult
    func request<Request>(
        _ request: Request,
        server: URL,
        authorization authorizationToken: AuthorizationToken? = nil,
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) async throws -> Data where Request: URLRequestConvertible {
        var urlRequest = URLRequest(
            request: request,
            server: server
        )
        if let token = authorizationToken {
            urlRequest.setAuthorization(token)
        }
        for (header, value) in headers.sorted(by: { $0.key < $1.key }) {
            urlRequest.addValue(value, forHTTPHeaderField: header)
        }
        let (data, urlResponse) = try await self.data(for: urlRequest)
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            fatalError("Invalid response type \(urlResponse)")
        }
        guard httpResponse.statusCode == statusCode else {
            throw NetworkObjectsError.invalidStatusCode(httpResponse.statusCode)
        }
        return data
    }
    
    @discardableResult
    func request<Request>(
        _ request: Request,
        server: URL,
        encoder: JSONEncoder,
        authorization authorizationToken: AuthorizationToken? = nil,
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) async throws -> Data where Request: EncodableURLRequest {
        var urlRequest = try URLRequest(
            request: request,
            server: server,
            encoder: encoder
        )
        if let token = authorizationToken {
            urlRequest.setAuthorization(token)
        }
        for (header, value) in headers.sorted(by: { $0.key < $1.key }) {
            urlRequest.addValue(value, forHTTPHeaderField: header)
        }
        let (data, urlResponse) = try await self.data(for: urlRequest)
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            fatalError("Invalid response type \(urlResponse)")
        }
        guard httpResponse.statusCode == statusCode else {
            throw NetworkObjectsError.invalidStatusCode(httpResponse.statusCode)
        }
        return data
    }
}
