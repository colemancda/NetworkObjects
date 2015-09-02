//
//  AccessControl.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/// Access Control level
public enum AccessControl: Int {
    
    /**  No access permission */
    case NoAccess = 0
    
    /**  Read Only permission */
    case ReadOnly = 1
    
    /**  Read and Write permission */
    case ReadWrite = 2
}