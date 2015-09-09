//
//  HTTPServer.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/5/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel


public extension Server {
    
    public final class HTTP: ServerType {
        
        // MARK: - Properties
        
        public let model: [Entity]
        
        public var dataSource: ServerDataSource
        
        public var delegate: ServerDelegate?
        
        public var settings = Server.Settings()
        
        // MARK: - Initialization
        
        public init(model: [Entity],
            dataSource: ServerDataSource,
            delegate: ServerDelegate? = nil) {
                
                self.model = model
                self.dataSource = dataSource
                self.delegate = delegate
        }
        
        // MARK: - Methods
        
        public func input(input: Server.HTTP.Request) -> SwiftFoundation.HTTP.Response {
            
            fatalError()
        }
    }
}