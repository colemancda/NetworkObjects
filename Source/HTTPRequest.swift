//
//  HTTPRequest.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/6/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public extension Server.HTTP {
    
    public struct Request {
        
        public var URI: String = ""
        
        public var method: HTTP.Method = .GET
        
        public var body: JSON.Object?
        
        public var headers: [String: String] = [:]
        
        public init() { }
    }
}

public extension RequestMessage {
    
    init?(HTTPRequest: Server.HTTP.Request, parameters: [Entity]) {
        
        let model = parameters
        
        self.metadata = HTTPRequest.headers
        
        switch HTTPRequest.method {
            
        case .GET:
            
            guard let (entityName, resourceID) = parseResourceURI(HTTPRequest.URI)
                else { return nil }
            
            guard let _: Entity = {
                for entity in model { if entity.name == entityName { return entity } }
                return nil
                }() else { return nil }
            
            let resource = Resource(entityName, resourceID)
            
            self.request = Request.Get(resource)
            
        case .DELETE:
            
            guard let (entityName, resourceID) = parseResourceURI(HTTPRequest.URI)
                else { return nil }
            
            guard let _: Entity = {
                for entity in model { if entity.name == entityName { return entity } }
                return nil
                }() else { return nil }
            
            let resource = Resource(entityName, resourceID)
            
            self.request = Request.Delete(resource)
            
        case .PUT:
            
            guard let (entityName, resourceID) = parseResourceURI(HTTPRequest.URI),
                let jsonObject = HTTPRequest.body
                else { return nil }
            
            guard let entity: Entity = {
                for entity in model { if entity.name == entityName { return entity } }
                return nil
                }() else { return nil }
            
            let resource = Resource(entityName, resourceID)
            
            guard let values = entity.convert(jsonObject)
                else { return nil }
            
            self.request = Request.Edit(resource, values)
            
        case .POST:
            
            // search
            if let entityName = parseSearchURI(HTTPRequest.URI) {
                
                guard let entity: Entity = {
                    for entity in model { if entity.name == entityName { return entity } }
                    return nil
                    }() else { return nil }
                
                guard let jsonObject = HTTPRequest.body,
                    let fetchRequest = FetchRequest(JSONValue: JSON.Value.Object(jsonObject), parameters: entity)
                    else { return nil }
                
                self.request = Request.Search(fetchRequest)
            }
                
                // create
            else {
                
                guard let entityName = parseCreateURI(HTTPRequest.URI) else { return nil }
                
                guard let entity: Entity = {
                    for entity in model { if entity.name == entityName { return entity } }
                    return nil
                    }() else { return nil }
                
                let values: ValuesObject?
                
                if let jsonObject = HTTPRequest.body {
                    
                    guard let convertedValues = entity.convert(jsonObject)
                        else { return nil }
                    
                    values = convertedValues
                }
                else { values = nil }
                
                self.request = Request.Create(entityName, values)
            }
            
        default: return nil
        }
    }
    
    func toHTTPRequest(serverURL: String, timeout: TimeInterval, options: [JSON.Serialization.WritingOption]) -> HTTP.Request {
        
        let url: String
        
        let method: HTTP.Method
        
        var jsonObject: JSON.Object?
        
        switch self.request {
            
        case let .Get(resource):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)"
            
            method = .GET
            
        case let .Delete(resource):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)"
            
            method = .DELETE
            
        case let .Edit(resource, values):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)"
            
            method = .PUT
            
            jsonObject = JSON.fromValues(values)
            
        case let .Create(entityName, values):
            
            url = serverURL + "/" + entityName
            
            method = .POST
            
            if let values = values {
                
                jsonObject = JSON.fromValues(values)
            }
            
        case let .Search(fetchRequest):
            
            url = serverURL + "/" + SearchPath + "/" + fetchRequest.entityName
            
            method = .POST
            
            jsonObject = fetchRequest.toJSON().objectValue
            
        case let .Function(resource, functionName, functionJSONObject):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)" + "/" + functionName
            
            method = .POST
            
            jsonObject = functionJSONObject
        }
        
        var httpRequest = HTTP.Request(URL: url)
        
        httpRequest.headers = self.metadata
        
        httpRequest.method = method
        
        httpRequest.timeoutInterval = timeout
        
        if let jsonObject = jsonObject {
            
            let jsonString = JSON.Value.Object(jsonObject).toString(options)!
            
            let data = jsonString.utf8.map({ (codeUnit) -> Byte in codeUnit })
            
            httpRequest.body = data
        }
        
        return httpRequest
    }
}

// MARK: - Private Functions

private let SearchPath = "search"

private func parseResourceURI(URI: String) -> (entityName: String, resourceID: String)? {
    
    let pathExpression = try! RegularExpression("/([a-z]+)/([.+])", options: [.CaseInsensitive, .ExtendedSyntax])
    
    guard let match = pathExpression.match(URI)
        where match.range.startIndex == 0 && match.range.endIndex == URI.utf8.count
        else { return nil }
    
    let entityName: String
    
    do {
        
        let range = match.subexpressionRanges[0]
        
        switch range {
            
        case let .Found(subexpressionRange):
            
            let start = URI.startIndex.advancedBy(subexpressionRange.startIndex)
            
            let end = URI.startIndex.advancedBy(subexpressionRange.endIndex)
            
            let stringRange = Range<String.Index>(start: start, end: end)
            
            entityName = URI[stringRange]
            
        default: fatalError()
        }
    }
    
    let resourceID: String
    
    do {
        
        let range = match.subexpressionRanges[1]
        
        switch range {
            
        case let .Found(subexpressionRange):
            
            let start = URI.startIndex.advancedBy(subexpressionRange.startIndex)
            
            let end = URI.startIndex.advancedBy(subexpressionRange.endIndex)
            
            let stringRange = Range<String.Index>(start: start, end: end)
            
            resourceID = URI[stringRange]
            
        default: fatalError()
        }
    }
    
    return (entityName, resourceID)
}

private func parseSearchURI(URI: String) -> String? {
    
    let pathExpression = try! RegularExpression("/\(SearchPath)/([a-z]+)", options: [.CaseInsensitive, .ExtendedSyntax])
    
    guard let match = pathExpression.match(URI)
        where match.range.startIndex == 0 && match.range.endIndex == URI.utf8.count
        else { return nil }
    
    let entityName: String
    
    do {
        
        let range = match.subexpressionRanges[0]
        
        switch range {
            
        case let .Found(subexpressionRange):
            
            let start = URI.startIndex.advancedBy(subexpressionRange.startIndex)
            
            let end = URI.startIndex.advancedBy(subexpressionRange.endIndex)
            
            let stringRange = Range<String.Index>(start: start, end: end)
            
            entityName = URI[stringRange]
            
        default: fatalError()
        }
    }
    
    return entityName
}

private func parseCreateURI(URI: String) -> String? {
    
    let pathExpression = try! RegularExpression("/([a-z]+)", options: [.CaseInsensitive, .ExtendedSyntax])
    
    guard let match = pathExpression.match(URI)
        where match.range.startIndex == 0 && match.range.endIndex == URI.utf8.count
        else { return nil }
    
    let entityName: String
    
    do {
        
        let range = match.subexpressionRanges[0]
        
        switch range {
            
        case let .Found(subexpressionRange):
            
            let start = URI.startIndex.advancedBy(subexpressionRange.startIndex)
            
            let end = URI.startIndex.advancedBy(subexpressionRange.endIndex)
            
            let stringRange = Range<String.Index>(start: start, end: end)
            
            entityName = URI[stringRange]
            
        default: fatalError()
        }
    }
    
    return entityName
}
