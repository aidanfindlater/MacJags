//
//  JagsLogPanelController.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-18.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsLogPanelController.h"
NSString * const Jags_LogSentNotification = @"JagsLogSent";

@implementation JagsLogPanelController
@synthesize log;

- (id)init
{
    self = [super init];
    if (self) {
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		
		[center addObserver:self
				   selector:@selector(logSentNotification:)
					   name:Jags_LogSentNotification
					 object:nil];
		
		log = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (IBAction)clear:(id)sender
{
	[log release];
	log = [[NSMutableArray alloc] init];
	[logTableView reloadData];
}

- (void)logSentNotification:(NSNotification *)notification
{
	[log addObject:[notification object]];
	[logTableView reloadData];
	[logTableView scrollRowToVisible:[logTableView numberOfRows] - 1];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [log count];
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	return [log objectAtIndex:rowIndex];
}

@end
