//
//  ParseJSON.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/27/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import Foundation

internal let PrettyPrintJSONDefault: Bool = {
    
    #if DEBUG
    return true
    #else
    return false
    #endif
}()

public extension NSData {
    
    convenience init?(JSON: AnyObject, prettyPrintJSON: Bool) {
        
        let data: NSData?
        
        do {
            
            data = try NSJSONSerialization.dataWithJSONObject(JSON, options: NSJSONWritingOptions())
        }
        catch _ {}
        
        self.init(data: data)
    }
    
    /** Parses the data as JSON into an array or dictionary. Doesn't throw. */
    func toJSON() -> AnyObject? {
        
        let json: AnyObject?
        
        do {
            
            json = try NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions())
        }
        catch _ {}
        
        return json
    }
}

public extension NSJSONWritingOptions {
    
    init(prettyPrinted: Bool) {
        
        if prettyPrinted {
            
            self = NSJSONWritingOptions.PrettyPrinted
        }
        else {
            
            self = NSJSONWritingOptions()
        }
    }
}