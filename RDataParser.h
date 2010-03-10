//
//  RDataParser.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-07.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RDataParser : NSObject {
	NSString *rDataString;
	NSScanner *scanner;
	NSCharacterSet *endTextCharacterSet;
	NSCharacterSet *symbolCharacterSet;
}

- (id)initWithString:(NSString *)anRDataString;
- (id)initWithURL:(NSURL *)aURL;

- (NSDictionary *)parseData;
- (NSDictionary *)parseAssignmentExpression;
- (NSString *)parseVariableName;
- (NSString *)parseAssignmentToken;
- (NSArray *)parseArray;
- (NSNumber *)parseNumber;
- (NSObject *)parseExpression;
- (NSString *)parseWhitespace;
- (NSString *)parseArraySeparator;

@end
