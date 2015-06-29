//
//  ErrorValue.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/25/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** Basic wrapper for error / value pairs. */
public enum ErrorValue<T> {
    
    case Error(ErrorType)
    case Value(T)
}