//
//  ServerPermission.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** Server Access Control level */
public enum ServerPermission: Int {
    
    /**  No access permission */
    case NoAccess = 0
    
    /**  Read Only permission */
    case ReadOnly = 1
    
    /**  Read and Write permission */
    case EditPermission = 2
}