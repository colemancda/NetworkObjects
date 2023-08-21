//
//  Entity.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation
import CoreModel

/// Network Objects Entity
public protocol NetworkEntity: Codable, Entity where ID: Codable {
    
    associatedtype CreateView: Codable
    
    associatedtype EditView: Codable
}
