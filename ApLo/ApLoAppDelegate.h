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
// NSApplicationDelegate Protocol
//*****************************************************************************
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;

//*****************************************************************************
// Implementation
//*****************************************************************************
- (NSDictionary *)environmentDictionaryFromFile:(NSString *)filename;
- (NSDictionary *)environmentDictionaryFromData:(NSData *)data;

@end
