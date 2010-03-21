//
//  ResultsDocument.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-16.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "ResultsDocument.h"

@implementation ResultsDocument

- (id)init
{
	[super init];
	if (!self) return nil;
	
	results = [[NSDictionary alloc] init];
	stats = [[NSDictionary alloc] init];
	
	return self;
}

- (void)dealloc
{
	[results release];
	[stats release];
	[super dealloc];
}

- (void)setResults:(NSDictionary *)newResults
{
	[newResults retain];
	[results release];
	results = newResults;
	
	NSMutableDictionary *newStats = [NSMutableDictionary dictionaryWithCapacity:[results count]];
	for (NSString *k in [results allKeys])
		[newStats setObject:[self statisticsFor:[results objectForKey:k]] forKey:k];
	
	[stats release];
	stats = nil;
	stats = [[NSDictionary alloc] initWithDictionary:newStats];
	
	NSLog(@"stats: %@", stats);
	
	[variableTableView reloadData];
}

- (NSString *)windowNibName
{
    return @"ResultsDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError
{
	return nil;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [results count];
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier] isEqual:@"name"]) {
		return [[results allKeys] objectAtIndex:rowIndex];
	} else {
		return [[stats objectForKey:[[results allKeys] objectAtIndex:rowIndex]]
				objectForKey:[aTableColumn identifier]];
	}
	
	return nil;
}


// Returns a dictionary of mean, SD, median, etc.
// for the given array
- (NSDictionary *)statisticsFor:(NSArray *)arr
{
	arr = [arr sortedArrayUsingSelector:@selector(compare:)];
	
	int n = [arr count];
	double sum = 0.0;
	double sumSquares = 0.0;
	
	double median = 0.0;
	if (n % 2 == 0)
		median = ([[arr objectAtIndex:(NSUInteger)(n/2)] doubleValue] + [[arr objectAtIndex:(NSUInteger)((n-1)/2)] doubleValue]) / 2.0;
	else
		median = [[arr objectAtIndex:(NSUInteger)(n/2)] doubleValue];
	
	for (NSNumber *num in arr) {
		sum += [num doubleValue];
		sumSquares += [num doubleValue] * [num doubleValue];
	}
	
	double mean = sum/(double)n;
	double variance = (sumSquares - sum * mean) / ((double)n - 1);
	double sd = sqrt(variance);
	
	double lowCI = mean - 1.959964 * sd;
	double highCI = mean + 1.959964 * sd;
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble:mean], @"mean",
			[NSNumber numberWithInt:n], @"N",
			[NSNumber numberWithDouble:median], @"median",
			[NSNumber numberWithDouble:sd], @"sd",
			[NSNumber numberWithDouble:lowCI], @"lowCI",
			[NSNumber numberWithDouble:highCI], @"highCI",
			nil];
}

@end
