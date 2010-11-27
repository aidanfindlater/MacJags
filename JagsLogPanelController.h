//
//  JagsLogPanelController.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-18.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const Jags_LogSentNotification; /**< Name of the notification that the log window responds to. */

/**
 * The JagsLogPanelController class manages the log panel.
 *
 * This windows responds to Jags_LogSentNotification notifications from
 * other windows, appending the text to the common log.
 */
@interface JagsLogPanelController : NSObject {
	IBOutlet NSPanel *logPanel;
	IBOutlet NSTableView *logTableView;
	
	NSMutableArray *log; /**< The array of strings that have been sent to the log window. */
}

@property (readonly) NSMutableArray *log;

- (IBAction)clear:(id)sender;

@end
