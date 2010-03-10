//
//  JagsAuxiliaryController.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-09.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsAuxiliaryController.h"


@implementation JagsAuxiliaryController
@synthesize document;

- (id)init
{
    self = [super init];
    if (self) {
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

		[center addObserver:self
				   selector:@selector(documentActivateNotification:)
					   name:JagsDocument_DocumentActivateNotification
					 object:nil];
		[center addObserver:self
				   selector:@selector(documentDeactivateNotification:)
					   name:JagsDocument_DocumentDeactivateNotification
					 object:nil];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (IBAction)runModel:(id)sender
{
	[document saveAndRun:sender];
}

- (IBAction)clearLog:(id)sender
{
	// Clear the log NSTableView
}

- (IBAction)showRunPanel:(id)sender
{
	[runPanel orderOut:sender];
}

- (IBAction)showLogPanel:(id)sender
{
	[logPanel orderOut:sender];
}

- (void)documentActivateNotification:(NSNotification *)notification
{
    [self setDocument: [notification object]];
	NSLog(@"New document: %@", document);
	NSLog(@"Variables: %@", [document variables]);
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

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [[document variables] objectAtIndex:rowIndex];
}


@end
