// 
// ApLoAppDelegate.m
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/07/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//
#import "ApLoAppDelegate.h"
#import "ApLoDocument.h"

@implementation ApLoAppDelegate

//*****************************************************************************
// Class methods
//*****************************************************************************
+ (void)initialize {
	
	//
	// +initialize might get called twice when KVO is in use (eg for NSKVONotifying_ApLoAppDelegate)!
	// 
	if(self!=[ApLoAppDelegate class]) return;
	
	//  
	// Register initial defaults
	// 
	NSMutableDictionary *defaults=[[NSMutableDictionary alloc]init];
	
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:@"WebKitDeveloperExtras"];
	
	[[NSUserDefaults standardUserDefaults]registerDefaults:defaults];
	[defaults release];
}

//*****************************************************************************
// NSApplicationDelegate Protocol
//*****************************************************************************
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	
	return NO;
}
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	
	//
	// Figure out if we should reuse a window
	// 
	NSDictionary	*d=[self environmentDictionaryFromFile:filename];
	
	if(!d) return NO;
	
	NSString	*windowName=[d objectForKey:@"APLO_WINDOW_NAME"];
	
	if(!windowName) return NO;
	
	NSArray		*docs=[NSApp orderedDocuments];
	
	for(NSDocument *doc in docs)
	{
		if([[doc displayName]isEqualToString:windowName])
		{
			return [(ApLoDocument *)doc relaunchWithEnvironment:d filename:filename];
		}
	}
	
	return NO;
}

//*****************************************************************************
// Implementation
//*****************************************************************************
- (NSDictionary *)environmentDictionaryFromFile:(NSString *)filename {
	
	return [self environmentDictionaryFromData:[NSData dataWithContentsOfFile:filename]];
}
- (NSDictionary *)environmentDictionaryFromData:(NSData *)data {
	
	if(!data) return nil;
	
	NSString			*envString=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
	NSArray				*lines=[envString componentsSeparatedByString:@"\n"];
	NSMutableDictionary	*newEnv=[NSMutableDictionary dictionary];
	
	[envString release];
	
	for(NSString *line in lines)
	{
		NSArray	*a=[line componentsSeparatedByString:@"="];
		
		if([a count]==2 && [[a objectAtIndex:0]length]>0)
		{
			[newEnv setObject:[a objectAtIndex:1] forKey:[a objectAtIndex:0]];
		}
	}
	
	return newEnv;
}

@end
