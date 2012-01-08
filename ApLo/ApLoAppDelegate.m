// 
// ApLoAppDelegate.m
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/07/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//
#import "ApLoAppDelegate.h"

@implementation ApLoAppDelegate


//*****************************************************************************
// Factory methods
//*****************************************************************************
- (id)init {
	
	if((self=[super init]))
	{
		DLog(@"%@  (%@)",_CMD,self);
		
		[[NSAppleEventManager sharedAppleEventManager]
			setEventHandler:self
			andSelector:@selector(getUrl:withReplyEvent:)
			forEventClass:kInternetEventClass
			andEventID:kAEGetURL
		];
		[[NSAppleEventManager sharedAppleEventManager]
		  setEventHandler:self 
		  andSelector:@selector(getUrl:withReplyEvent:) 
		  forEventClass:'WWW!' 
		  andEventID:'OURL'];
		
		DLog(@"url: %@",[[NSBundle mainBundle]bundleURL]);
		
		OSStatus s1=LSRegisterURL((CFURLRef)[[NSBundle mainBundle]bundleURL],true);
		DLog(@"s1: %d",s1);
		
		NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
		DLog(@"bundleID: %@",bundleID);
		OSStatus httpResult=LSSetDefaultHandlerForURLScheme((CFStringRef)@"aplo", (CFStringRef)bundleID);
		
		DLog(@"httpResult new: %d",httpResult);
		
	}
	
	return self;
}

//*****************************************************************************
// URL handling
//*****************************************************************************
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	
	id			o=[event paramDescriptorForKeyword:keyDirectObject];
	NSString	*urls = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	
	DLog(@"o: %@",o);
	DLog(@"urls: %@",urls);
	
}

@end
