//
//  ResultsDocument.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-16.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ResultsDocument : NSDocument {
	IBOutlet NSTableView *variableTableView;
	NSDictionary *results;
	NSDictionary *stats;
}

- (void)setResults:(NSDictionary *)newResults;
- (NSDictionary *)statisticsFor:(NSArray *)arr;

@end
