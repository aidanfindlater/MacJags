//
//  JagsRunPanelController.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-09.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsRunPanelController.h"


@implementation JagsRunPanelController
@synthesize document;

- (id)init
{
    self = [super init];
    if (self) {
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

		[center addObserver:self
				   selector:@selector(documentActivateNotification:)
					   name:Jags_DocumentActivateNotification
					 object:nil];
		[center addObserver:self
				   selector:@selector(documentDeactivateNotification:)
					   name:Jags_DocumentDeactivateNotification
					 object:nil];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[document release];
    [super dealloc];
}

- (IBAction)runModel:(id)sender
{
	[document saveAndRun:sender];
}

- (IBAction)showRunPanel:(id)sender
{
	[runPanel orderOut:sender];
}

- (void)documentActivateNotification:(NSNotification *)notification
{
    [self setDocument: [notification object]];
	[variableTableView reloadData];
}

- (void)documentDeactivateNotification:(NSNotification *)notification
{
    [self setDocument: nil];
	[variableTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[document variables] count];
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier] isEqual:@"names"]) {
		return [[document variables] objectAtIndex:rowIndex];
	}
	
	if ([[aTableColumn identifier] isEqual:@"monitors"]) {
		return [[document monitors] objectAtIndex:rowIndex];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(NSInteger)rowIndex;
{
	if ([[aTableColumn identifier] isEqual:@"monitors"]) {
		[[document monitors]
		 replaceObjectAtIndex:rowIndex
		 withObject:[NSNumber numberWithBool:[anObject boolValue]]];
	}
}


@end
