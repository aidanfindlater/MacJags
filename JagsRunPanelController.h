//
//  JagsRunPanelController.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-09.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JagsDocument.h"

/**
 * The JagsRunPanelController class manages the "run" panel.
 *
 * This panel includes the variable monitors and options that control
 * the JAGS execution.
 */
@interface JagsRunPanelController : NSObject <NSTableViewDataSource> {
	IBOutlet NSPanel *runPanel;
	
	IBOutlet NSTableView *variableTableView;
	IBOutlet NSTextField *numberOfChainsTextField;
	IBOutlet NSTextField *burnInTextField;
	IBOutlet NSTextField *samplesTextField;
	
	JagsDocument *document;
}

@property (retain,readwrite) JagsDocument *document;

- (IBAction)runModel:(id)sender;
- (IBAction)showRunPanel:(id)sender;

@end
