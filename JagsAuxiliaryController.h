//
//  JagsAuxiliaryController.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-09.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JagsDocument.h"

@interface JagsAuxiliaryController : NSObject <NSTableViewDataSource> {
	IBOutlet NSPanel *runPanel;
	IBOutlet NSPanel *logPanel;
	
	IBOutlet NSTableView *variableTableView;
	IBOutlet NSTextField *burnInTextField;
	IBOutlet NSTextField *samplesTextField;
	
	IBOutlet NSTableView *logTableView;
	
	JagsDocument *document;
}

@property (retain,readwrite) JagsDocument *document;

- (IBAction)runModel:(id)sender;
- (IBAction)clearLog:(id)sender;

- (IBAction)showRunPanel:(id)sender;
- (IBAction)showLogPanel:(id)sender;

@end
