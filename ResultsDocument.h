//
//  ResultsDocument.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-16.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * The ResultsDocument class displays the summary statistics of monitored variables from a JAGS run.
 */
@interface ResultsDocument : NSDocument {
	IBOutlet NSTableView *variableTableView;	/**< Table view of monitored variables statistics */
	
	NSDictionary *results;	/**< Dictionary of monitored variables and their samples */
	NSDictionary *stats;	/**< Dictionary of monitored variables and their summary statistics */
}

- (void)setResults:(NSDictionary *)newResults;
- (NSDictionary *)statisticsFor:(NSArray *)arr;

@end
