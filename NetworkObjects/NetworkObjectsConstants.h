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

// valid predicate comparators
// https://developer.apple.com/library/mac/documentation/cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795

// Basic
#define kNOSearchPredicateIsEqualComparator @"=="
#define kNOSearchPredicateGreaterThanOrEqualComparator @">="
#define kNOSearchPredicateLessThanOrEqualComparator @"<="
#define kNOSearchPredicateGreaterThanComparator @">"
#define kNOSearchPredicateLessThanComparator @"<"
#define kNOSearchPredicateNotEqualComparator @"!="
#define KNOSearchPredicateBetweenComparator @"BETWEEN"

// Boolean
#define KNOSearchTruePredicate @"TRUEPREDICATE"
#define kNOSearchFalsePredicate @"FALSEPREDICATE"

// Compound
#define kNOSearchAndPredicate @"&&"
#define kNOSearchOrPredicate @"||"
#define kNOSearchNotPredicate @"!"

// String
#define kNOSearchBeginsWithComparator @"BEGINSWITH"
#define kNOSearchContainsComparator @"CONTAINS"
#define kNOSearchEndsWithComparator @"ENDSWITH"
#define kNOSearchLikeComparator @"LIKE"
#define kNOSearchMatchesComparator @"MATCHES"


#endif
