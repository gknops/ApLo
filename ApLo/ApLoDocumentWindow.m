// 
// ApLoDocumentWindow.m
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/04/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//
#import "ApLoDocumentWindow.h"

@implementation ApLoDocumentWindow

//*****************************************************************************
// Implementation
//*****************************************************************************
-(void)sendEvent:(NSEvent *)event {
	
	//
	// To allow clicks (eg on links) when the window is not main
	// 
	if([event type]==NSLeftMouseDown
		&& ![self isMainWindow]
		&& [aploWebView
			mouse:[aploWebView convertPoint:[event locationInWindow]
fromView:nil]
			inRect:[aploWebView visibleRect]
		]
	)
	{
		[super sendEvent:event];
	}
	
	[super sendEvent:event];
}


//*****************************************************************************
// Find Panel support
//*****************************************************************************
- (void)performFindPanelAction:(id)sender {
	
	DLog(@"%@  sender: %@  (%@)",_CMD,sender,self);
	
	NSBeep();
}
-(BOOL)validateMenuItem:(NSMenuItem *)theMenuItem
{
	DLog(@"%@  theMenuItem: %@  (%@)",_CMD,theMenuItem,self);
	
	return NO;
}
- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem {
	
	DLog(@"%@  anItem: %@  (%@)",_CMD,anItem,self);
	
	return NO;
}

//*****************************************************************************
// Synthesized Accessors
//*****************************************************************************
@synthesize aploWebView;

@end
