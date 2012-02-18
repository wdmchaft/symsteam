//
//  PreferencesController.h
//  SymSteam
//
//  Created by Alex Jackson on 15/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController

@property (strong) IBOutlet NSTextField *localPathTextField;
@property (strong) IBOutlet NSTextField *symbolicPathTextField;


-(IBAction)chooseLocalSteamAppsPath:(id)sender;
-(IBAction)chooseSymbolicSteamAppsPath:(id)sender;

@end