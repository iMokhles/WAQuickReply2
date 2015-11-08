//
//  WAQuickReply2ListController.h
//  WAQuickReply2
//
//  Created by iMokhles on 29.10.2015.
//  Copyright (c) 2015 iMokhles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <spawn.h>
#import <substrate.h>
#import <dlfcn.h>
#import <CommonCrypto/CommonDigest.h>
#import <iMoMacros.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>
#import <Couria/Couria.h>
#import <MobileCoreServices/MobileCoreServices.h> // For UTI
#import <imounbox/imounbox.h>
#import <UIKit/UIImage2.h>

#import "FMDB/FMDatabase.h"
#import "FMDB/FMDatabaseAdditions.h"

#define WAQuickReplyAppVersionGreaterThanOrEqualTo(v)  ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define WAQuickReplyAppVersionLessThanOrEqualTo(v)     ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define WAQuickReplyAppVersionGreaterThan(v)           ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] compare:v options:NSNumericSearch] == NSOrderedDescending)

__attribute__((always_inline, visibility("hidden")))
static BOOL isThisFileExiste(const char *path) {
    return (access(path,F_OK) != -1);
}

typedef NS_ENUM(NSUInteger, BKSProcessAssertionReason)
{
    kProcessAssertionReasonAudio = 1,
    kProcessAssertionReasonLocation,
    kProcessAssertionReasonExternalAccessory,
    kProcessAssertionReasonFinishTask,
    kProcessAssertionReasonBluetooth,
    kProcessAssertionReasonNetworkAuthentication,
    kProcessAssertionReasonBackgroundUI,
    kProcessAssertionReasonInterAppAudioStreaming,
    kProcessAssertionReasonViewServices
};

typedef NS_ENUM(NSUInteger, ProcessAssertionFlags)
{
    ProcessAssertionFlagNone = 0,
    ProcessAssertionFlagPreventSuspend = 1 << 0,
    ProcessAssertionFlagPreventThrottleDownCPU = 1 << 1,
    ProcessAssertionFlagAllowIdleSleep = 1 << 2,
    ProcessAssertionFlagWantsForegroundResourcePriority = 1 << 3
};

typedef enum
{
	NSNotificationSuspensionBehaviorDrop = 1,
	NSNotificationSuspensionBehaviorCoalesce = 2,
	NSNotificationSuspensionBehaviorHold = 3,
	NSNotificationSuspensionBehaviorDeliverImmediately = 4
} NSNotificationSuspensionBehavior;

@interface NSDistributedNotificationCenter : NSNotificationCenter
+ (instancetype)defaultCenter;
- (void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(NSString *)notificationSender suspensionBehavior:(NSNotificationSuspensionBehavior)suspendedDeliveryBehavior;
- (void)removeObserver:(id)notificationObserver name:(NSString *)notificationName object:(NSString *)notificationSender;
- (void)postNotificationName:(NSString *)notificationName object:(NSString *)notificationSender userInfo:(NSDictionary *)userInfo deliverImmediately:(BOOL)deliverImmediately;
@end

static NSString *formatDictValue(NSObject *object) {
    return object ? (NSString *)object : @"";
}

@interface BBBulletin : NSObject
@property(retain, nonatomic) NSDictionary *context;
@property(retain, nonatomic) NSMutableDictionary* actions;
@property(copy, nonatomic) NSArray* buttons;
@end

@interface BBBulletinRequest : BBBulletin
@end

@interface UIConcreteLocalNotification : UILocalNotification
@end

@interface WAQuickReplyMessage : NSObject <CouriaMessage>
@property (copy) id content;
@property (assign) BOOL outgoing;
@property (copy) NSDate *timestamp;
//  {
// 	BOOL _outgoing;
//     id _content;
//     NSDate *_timestamp;
// }
// @property(retain) NSDate *timestamp;
// @property BOOL outgoing; 
// @property(retain) id content;
@end

@interface WAQuickReplyHandler : NSObject <CouriaExtension>
+ (instancetype)sharedInstance;
@end

// Calling App & Background

@interface BKSProcessAssertion : NSObject
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (id)initWithBundleIdentifier:(id)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (void)invalidate;
@property(readonly, nonatomic) BOOL valid;
@end

@interface FBProcess : NSObject
@end

@interface BKSProcess : NSObject
- (void)_handleExpirationWarning:(id)xpcdictionary;
@end

@interface FBApplicationProcess : FBProcess
@property (nonatomic, getter=isConnectedToExternalAccessory) BOOL connectedToExternalAccessory;
@property (nonatomic, getter=isNowPlayingWithAudio) BOOL nowPlayingWithAudio;
@property (nonatomic, getter=isRecordingAudio) BOOL recordingAudio;
- (void)processWillExpire:(BKSProcess *)process;
@end

@interface FBProcessManager : NSObject
+ (FBProcessManager *)sharedInstance;
- (id)createApplicationProcessForBundleID:(id)arg1;
@end

@interface SBApplication
- (void)activate;
- (void)processDidLaunch:(id)arg1;
- (void)processWillLaunch:(id)arg1;
- (void)resumeForContentAvailable;
- (void)resumeToQuit;
- (void)_sendDidLaunchNotification:(_Bool)arg1;
- (void)notifyResumeActiveForReason:(long long)arg1;
@property(readonly, nonatomic) int pid;
@end

@interface UIApplication ()
- (BOOL)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;  
@end

@interface SBApplicationController
+(id) sharedInstance;
-(SBApplication*) applicationWithBundleIdentifier:(NSString*)identifier;
-(SBApplication*)applicationWithPid:(int)arg1;
@end

/* App Info Dec */

@interface LSApplicationWorkspace : NSObject
+ (LSApplicationWorkspace *)defaultWorkspace;
- (BOOL)installApplication:(NSURL *)path withOptions:(NSDictionary *)options;
- (BOOL)uninstallApplication:(NSString *)identifier withOptions:(NSDictionary *)options;
- (BOOL)applicationIsInstalled:(NSString *)appIdentifier;
- (NSArray *)allInstalledApplications;
- (NSArray *)allApplications;
- (NSArray *)applicationsOfType:(unsigned int)appType; // 0 for user, 1 for system
@end

@interface LSApplicationProxy : NSObject
+ (LSApplicationProxy *)applicationProxyForIdentifier:(id)appIdentifier;
@property(readonly) NSString * applicationIdentifier;
@property(readonly) NSString * bundleVersion;
@property(readonly) NSString * bundleExecutable;
@property(readonly) NSArray * deviceFamily;
@property(readonly) NSURL * bundleContainerURL;
@property(readonly) NSString * bundleIdentifier;
@property(readonly) NSURL * bundleURL;
@property(readonly) NSURL * containerURL;
@property(readonly) NSURL * dataContainerURL;
@property(readonly) NSString * localizedShortName;
@property(readonly) NSString * localizedName;
@property(readonly) NSString * shortVersionString;
@property(readonly) NSDictionary * groupContainers;
@property(readonly) NSArray * groupIdentifiers;

@end

// WhatsApp

@interface WAChatSession : NSObject
@property(retain, nonatomic) NSNumber *unreadCount; // @dynamic unreadCount;
@end

@interface WAChatStorage : NSObject
- (id)newOrExistingChatSessionForJID:(id)arg1; // new beta
- (void)sendMessageWithText:(id)arg1 metadata:(id)arg2 inChatSession:(id)arg3; // new beta
- (void)sendMessageWithText:(id)arg1 inChatSession:(id)arg2;
- (void)sendMessageWithImage:(id)arg1 caption:(id)arg2 inChatSession:(id)arg3 completion:(id)arg4;
- (void)retrySendingMessage:(id)arg1;
- (id)messagesForSession:(id)arg1 startOffset:(unsigned long long)arg2 limit:(unsigned long long)arg3;
- (void)sendVideoAtURL:(id)arg1 caption:(id)arg2 collectionID:(id)arg3 index:(long long)arg4 count:(long long)arg5 inChatSession:(id)arg6 completion:(id)arg7;
@end

@interface XMPPConnection : NSObject
- (void)setXmppUser:(id)arg1;
- (void)reloadPassword;
- (void)connect;
@end

@interface WASharedAppData : NSObject
+ (WAChatStorage *)chatStorage;
+ (NSString *)userJID;
+ (XMPPConnection *)xmppConnection;
@end

@interface NSString ( containsCategory )
- (BOOL) containsString: (NSString*) substring;
@end

@interface WAQuickReply2Helper : NSObject

// Preferences
+ (NSString *)preferencesPath;
+ (CFStringRef)preferencesChanged;

// UIWindow to present your elements
// u can show/hide it using ( setHidden: NO/YES )
+ (UIWindow *)mainWAQuickReply2Window;
+ (UIViewController *)mainWAQuickReply2ViewController;

// Checking App Version
+ (BOOL)isAppVersionGreaterThanOrEqualTo:(NSString *)appversion;
+ (BOOL)isAppVersionLessThanOrEqualTo:(NSString *)appversion;

// Checking OS Version
+ (BOOL)isIOS83_OrGreater;
+ (BOOL)isIOS80_OrGreater;
+ (BOOL)isIOS70_OrGreater;
+ (BOOL)isIOS60_OrGreater;
+ (BOOL)isIOS50_OrGreater;
+ (BOOL)isIOS40_OrGreater;

// Checking Device Type
+ (BOOL)isIPhone6_Plus;
+ (BOOL)isIPhone6;
+ (BOOL)isIPhone5;
+ (BOOL)isIPhone4_OrLess;

// Checking Device Interface
+ (BOOL)isIPad;
+ (BOOL)isIPhone;

// Checking Device Retina
+ (BOOL)isRetina;

// Checking UIScreen sizes
+ (CGFloat)screenWidth;
+ (CGFloat)screenHeight;

// private methods
+ (UIImage *)getUserImageFromJID:(NSString *)userJID;
+ (NSString *)getUserJidFromBulletin:(BBBulletinRequest *)bulletin;
+ (NSString *)getUserNameFromJID:(NSString *)userJID;
+ (NSDictionary *)getAppInfoFromAppID:(NSString *)appIdentifier;
+ (NSArray *)getAllChatSessionsContactsFromKeyword:(NSString *)keyword;
+ (NSArray *)getAllMessagesFromSessionWithJID:(NSString *)userJID;
+ (void)markAsReadChatSessionForJID:(NSString *)userJID;

// database methods
+ (BOOL)getBOOLFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery;
+ (long)getLongFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery;
+ (double)getDoubleFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery;
+ (NSDictionary *)getDictionaryFromDataBase:(NSString *)dataBasePath fromSelectQuery:(NSString *)selectQuery;
+ (NSString *)getStringFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery;
+ (NSMutableArray *)getDataBaseInfo:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery;
+ (NSArray *)getMessagesFromDataBase:(NSString *)dataBasePath fromSelectQuery:(NSString *)selectQuery;
+ (BOOL)updateDataBase:(NSString *)dataBasePath withUpdateQuery:(NSString *)updateQuery;

// string
+ (NSString *)MD5String:(NSString *)string;

// image
+ (UIImage *)makeRoundedImage:(UIImage *) image radius: (float) radius;
+ (UIImage *)imageByScaling:(UIImage *)image toSize:(CGSize)targetSize;

// mime type
+ (NSString *)mimeTypeForFileAtPath:(NSString *)path;

// path extensions
+(BOOL)handleImageExtension:(NSString *)fileExt;
+(BOOL)handleVideoExtension:(NSString *)fileExt;
@end
