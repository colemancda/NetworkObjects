//
//  Define.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/28/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

internal let TestBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjectsTests")!

internal let TestModel = NSManagedObjectModel.mergedModelFromBundles([TestBundle])!

internal let ServerTestingPort: UInt = 8089

