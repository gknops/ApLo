// 
// ApLoDocumentWindow.h
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/04/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//

@class WebView;

@interface ApLoDocumentWindow: NSPanel
{
	PROP(assign,IBOutlet) WebView	*aploWebView;
}
@property (assign) IBOutlet	WebView	*aploWebView;

//*****************************************************************************
// Implementation
//*****************************************************************************
-(void)sendEvent:(NSEvent *)event;

//*****************************************************************************
// Synthesized Accessors
//*****************************************************************************
// @synthesize aploWebView;

@end
