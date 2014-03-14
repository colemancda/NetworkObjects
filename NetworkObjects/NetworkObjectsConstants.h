//
//  NetworkObjectsConstants.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/10/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#ifndef NetworkObjects_NetworkObjectsConstants_h
#define NetworkObjects_NetworkObjectsConstants_h

#define NetworkObjectsErrorDomain @"com.ColemanCDA.NetworkObjects.ErrorDomain"

// search parameters

typedef NS_ENUM(NSUInteger, NOSearchParameter) {
    
    NOSearchPredicateParameter,
    NOSearchFetchLimitParameter,
    NOSearchFetchOffsetParameter,
    NOSearchIncludesSubentitiesParameter,
    NOSearchSortDescriptorsParameter
    
};

// Compound
#define kNOSearchAndPredicate @"&&"
#define kNOSearchOrPredicate @"||"
#define kNOSearchNotPredicate @"!"


#endif
