//
//  SteamAppsController.m
//  SymSteam
//
//  Created by Alex Jackson on 05/04/2012.


#import "SteamAppsController.h"

static NSString * const steamAppsSymbolicLinkPathKey = @"steamAppsSymbolicLinkPath";
static NSString * const steamAppsLocalPathKey = @"steamAppsLocalPath";
static NSString * const growlNotificationsEnabledKey = @"growlNotificationsEnabled";
static NSString * const symbolicPathDestinationKey = @"symbolicPathDestination";
static NSString * const setupComplete = @"setupComplete";

@implementation SteamAppsController

@synthesize steamDriveIsConnected = _steamDriveIsConnected;

-(id)init{
    self = [super init];
    if(self){
        _steamDriveIsConnected = NO;
    }
    return self;
}

-(void)didMountDrive:(NSNotification *)aNotification{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:setupComplete])
        return;
    
    if(self.steamDriveIsConnected)
        return;
    
    NSURL *notificationDriveURL = [aNotification.userInfo valueForKey:NSWorkspaceVolumeURLKey];
    NSFileManager *fManager = [[NSFileManager alloc] init];
    if(![[notificationDriveURL.pathComponents objectAtIndex:2] isEqualToString:[[[[NSUserDefaults standardUserDefaults] stringForKey:symbolicPathDestinationKey]pathComponents]objectAtIndex:2]])
        return;
    
    if(![fManager fileExistsAtPath:[[NSUserDefaults standardUserDefaults] stringForKey:symbolicPathDestinationKey]]){
        if([[NSUserDefaults standardUserDefaults] boolForKey:growlNotificationsEnabledKey]){
        [GrowlApplicationBridge notifyWithTitle:@"Could Not Find SteamApps Folder"
                                    description:@"The folder was not found at its expected location on your Steam Drive."
                               notificationName:@"noSteamAppsFound"
                                       iconData:nil
                                       priority:0
                                       isSticky:NO
                                   clickContext:nil];
        }
        return;
    }
    
    if(![self makeSymbolicSteamAppsPrimary])
        return;
    
    self.steamDriveIsConnected = YES;
    if([[NSUserDefaults standardUserDefaults] boolForKey:growlNotificationsEnabledKey]){
    [GrowlApplicationBridge notifyWithTitle:@"The symbolic SteamApps Folder is now active"
                                description:@"Your Steam drive was plugged in."
                           notificationName:@"symbolicSteamAppsPrimary"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
    }
}

-(void)didUnMountDrive:(NSNotification *)aNotification{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:setupComplete])
        return;
    
    if(!self.steamDriveIsConnected)
        return;
    
    NSFileManager *fManager = [[NSFileManager alloc] init];
    if([fManager fileExistsAtPath:[[NSUserDefaults standardUserDefaults] stringForKey:symbolicPathDestinationKey]])
        return;
    
    if(![self makeLocalSteamAppsPrimary]){
        self.steamDriveIsConnected = NO;
        return;
    }
    
    self.steamDriveIsConnected = NO;
    if([[NSUserDefaults standardUserDefaults] boolForKey:growlNotificationsEnabledKey]){
    [GrowlApplicationBridge notifyWithTitle:@"The local SteamApps folder is now active"
                                description:@"Your Steam drive was unplugged."
                           notificationName:@"localSteamAppsPrimary"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
    }
}

-(BOOL)makeSymbolicSteamAppsPrimary{
    NSFileManager *fManager = [[NSFileManager alloc] init];
    
    NSError *localFolderRename;
    NSString *newLocalPath = [[NSString alloc] initWithFormat:@"%@/SteamAppsLoc", [[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsLocalPathKey] stringByDeletingLastPathComponent]];
    
    if(![fManager moveItemAtPath:[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsLocalPathKey] toPath:newLocalPath error:&localFolderRename]){
        if([[NSUserDefaults standardUserDefaults] boolForKey:growlNotificationsEnabledKey]){
            [GrowlApplicationBridge notifyWithTitle:@"Error Renaming Local Steam Folder" 
                                        description:[localFolderRename localizedDescription]
                                   notificationName:@"symbolicPrimaryFail" 
                                           iconData:nil 
                                           priority:0 
                                           isSticky:NO 
                                       clickContext:nil];
        }
        return NO;
    }
    
    NSError *symbFolderRename;
    if(![fManager moveItemAtPath:[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsSymbolicLinkPathKey ] toPath:[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsLocalPathKey ] error:&symbFolderRename]){
        if([[NSUserDefaults standardUserDefaults] boolForKey:growlNotificationsEnabledKey]){
            [GrowlApplicationBridge notifyWithTitle:@"Error Renaming Symbolic Folder"
                                        description:[localFolderRename localizedDescription]
                                   notificationName:@"symbolicPrimaryFail"
                                           iconData:nil
                                           priority:0
                                           isSticky:NO
                                       clickContext:nil];
        }
        return NO;
    }
    
    return YES;
}

-(BOOL)makeLocalSteamAppsPrimary{
    NSFileManager *fManager = [[NSFileManager alloc] init];
    
    NSError *renameSymbolicError;
    if(![fManager moveItemAtPath:[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsLocalPathKey] toPath:[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsSymbolicLinkPathKey] error:&renameSymbolicError]){
        if([[NSUserDefaults standardUserDefaults] boolForKey:growlNotificationsEnabledKey]){
            [GrowlApplicationBridge notifyWithTitle:@"Error reverting symbolic SteamApps folder"
                                        description:[renameSymbolicError localizedDescription]
                                   notificationName:@"localPrimaryFail"
                                           iconData:nil
                                           priority:0
                                           isSticky:NO
                                       clickContext:nil];
        }
        return NO;
    }
    
    NSError *renameLocalError;
    NSString *currentSteamAppsPath = [[NSString alloc] initWithFormat:@"%@/SteamAppsLoc", [[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsLocalPathKey]stringByDeletingLastPathComponent]];
    if(![fManager moveItemAtPath:currentSteamAppsPath toPath:[[NSUserDefaults standardUserDefaults] valueForKey:steamAppsLocalPathKey] error:&renameLocalError]){
        if([[NSUserDefaults standardUserDefaults] boolForKey:growlNotificationsEnabledKey]){
            [GrowlApplicationBridge notifyWithTitle:@"Error reverting local SteamApps folder" 
                                        description:[renameSymbolicError localizedDescription]
                                   notificationName:@"localPrimaryFail"
                                           iconData:nil
                                           priority:0
                                           isSticky:NO
                                       clickContext:nil];
        }
        return NO;
    }
    return YES;
}

@end
