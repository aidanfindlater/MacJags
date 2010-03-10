//
//  JagsRunPanelController.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-09.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JagsDocument.h"

@interface JagsRunPanelController : NSObject <NSTableViewDataSource> {
	IBOutlet NSPanel *runPanel;
	
	IBOutlet NSTableView *variableTableView;
	IBOutlet NSTextField *burnInTextField;
	IBOutlet NSTextField *samplesTextField;
	
	JagsDocument *document;
}

@property (retain,readwrite) JagsDocument *document;

- (IBAction)runModel:(id)sender;
- (IBAction)showRunPanel:(id)sender;

@end
