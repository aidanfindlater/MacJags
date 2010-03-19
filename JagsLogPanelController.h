//
//  JagsLogPanelController.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-18.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const Jags_LogSentNotification;

@interface JagsLogPanelController : NSObject {
	IBOutlet NSPanel *logPanel;
	IBOutlet NSTableView *logTableView;
	
	NSMutableArray *log;
}

@property (readonly) NSMutableArray *log;

- (IBAction)clear:(id)sender;

@end
