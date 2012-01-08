// 
// ApLoAppDelegate.h
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/07/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//

@interface ApLoAppDelegate: NSObject <NSApplicationDelegate>
{
}

//*****************************************************************************
// Factory methods
//*****************************************************************************
- (id)init;

//*****************************************************************************
// URL handling
//*****************************************************************************
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

@end
