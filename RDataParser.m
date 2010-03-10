//
//  RDataParser.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-07.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "RDataParser.h"


@implementation RDataParser


- (id)initWithString:(NSString *)anRDataString
{
	self = [super init];
	if (!self) return nil;
	
	rDataString = [anRDataString retain];
	
	NSMutableCharacterSet *endTextMutableCharacterSet = [[NSCharacterSet newlineCharacterSet] mutableCopy];
	[endTextMutableCharacterSet addCharactersInString:@"<="];
	endTextCharacterSet = endTextMutableCharacterSet;
	
	NSMutableCharacterSet *symbolMutableCharacterSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	[symbolMutableCharacterSet addCharactersInString:@"_."];
	symbolCharacterSet = symbolMutableCharacterSet;
	
	return self;
}

- (id)initWithURL:(NSURL *)aURL
{
	NSError *error;
	self = [self initWithString:[NSString stringWithContentsOfURL:aURL encoding:NSUTF8StringEncoding error:&error]];
	
	if (error) {
		NSLog(@"RDataParser could not read file: %@", error);
		return nil;
	}
	
	if (!self) return nil;
	
	return self;
}

- (void)dealloc
{
	[rDataString release];
	[endTextCharacterSet release];
	[symbolCharacterSet release];
	[super dealloc];
}


- (NSDictionary *)parseData
{
	scanner = [[NSScanner alloc] initWithString:rDataString];
	[scanner setCharactersToBeSkipped:[[NSCharacterSet whitespaceAndNewlineCharacterSet] autorelease]];
	
	NSMutableDictionary *results = [NSMutableDictionary dictionary];
	
	[self parseWhitespace];
	
	NSDictionary *variable = [[self parseAssignmentExpression] retain];
	
	if (!variable)
		return results;
	
	while (variable) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[results addEntriesFromDictionary:variable];
		
		[variable release];
		
		[self parseWhitespace];
		
		variable = [[self parseAssignmentExpression] retain];
		
		[pool drain];
	}
	
	[scanner release];
	scanner = nil;
	
	return results;	
}

- (NSDictionary *)parseAssignmentExpression
{
	NSString *name = [self parseVariableName];
	if (!name) return nil;
	
	if (![self parseAssignmentToken]) return nil;
	
	id value = [self parseExpression];
	
	if (value) {
		if (![value respondsToSelector:@selector(count)])
			value = [NSArray arrayWithObject:value];
		
		return [NSDictionary dictionaryWithObject:value forKey:name];
	}
	
	return nil;
}

- (NSObject *)parseExpression
{
	NSNumber *numberValue = [self parseNumber];
	if (numberValue)
		return numberValue;
	
	NSArray *arrayValue = [self parseArray];
	if (arrayValue)
		return arrayValue;
	
	return nil;
}

- (NSString *)parseVariableName
{
	NSString *name;
	NSString *openQuote;
	NSString *closeQuote;
	
	BOOL quoted = [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""] intoString:&openQuote];
	
	if (quoted && [openQuote length] > 1)
		return nil;
	
	[scanner scanCharactersFromSet:symbolCharacterSet intoString:&name];
	
	if (quoted && (![scanner scanString:openQuote intoString:&closeQuote] || ![openQuote isEqual:closeQuote]))
		return nil;
	
	if (name)
		return name;
	else
		return nil;
}

- (NSString *)parseAssignmentToken
{
	if ([scanner scanString:@"=" intoString:NULL])
		return @"=";
	
	else if ([scanner scanString:@"<-" intoString:NULL])
		return @"<-";
	
	else
		return nil;
}

- (NSArray *)parseArray
{
	NSUInteger location = [scanner scanLocation];
	
	if (![scanner scanString:@"c(" intoString:NULL]) {
		[scanner setScanLocation:location];
		return nil;
	}
	
	NSMutableArray *array = [NSMutableArray array];
	while (YES) {
		NSObject *value = [self parseExpression];
		
		if (!value) {
			[scanner setScanLocation:location];
			return nil;
		}
		
		[array addObject:value];
		
		if (![self parseArraySeparator])
			break;
	}
	
	if (![scanner scanString:@")" intoString:NULL]) {
		[scanner setScanLocation:location];
		return nil;
	}
	
	return array;	
}

- (NSNumber *)parseNumber
{
	float num;
	if (![scanner scanFloat:&num])
		return nil;
	return [NSNumber numberWithFloat:num];
}

- (NSString *)parseArraySeparator
{
	if ([scanner scanString:@"," intoString:NULL])
		return @",";
	else
		return nil;
}	

- (NSString *)parseWhitespace
{
	NSString *matchedWhitespace = nil;
	[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&matchedWhitespace];
	return matchedWhitespace;
}	

@end
