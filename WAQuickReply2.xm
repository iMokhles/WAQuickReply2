//
//  WAQuickReply2.x
//  WAQuickReply2
//
//  Created by iMokhles on 29.10.2015.
//  Copyright (c) 2015 iMokhles. All rights reserved.
//

#import "WAQuickReply2Helper.h"

static NSBundle *whatsAppBundle() {
    NSDictionary *appInfoGet = [WAQuickReply2Helper getAppInfoFromAppID:@"net.whatsapp.WhatsApp"];
    NSString *appPathBundle = [appInfoGet objectForKey:@"APP_PATH"];
    NSBundle *bundle = [NSBundle bundleWithPath:appPathBundle];
    return bundle;
}

static void close_WhatsApp() {
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:@"net.whatsapp.WhatsApp"];
    if (![app pid]) {
        return;
    }
    FBApplicationProcess *appProcess = MSHookIvar<FBApplicationProcess *>(app, "_process");
	if (!appProcess.nowPlayingWithAudio && !appProcess.recordingAudio) {
		BKSProcess *appBKSProcess = MSHookIvar<BKSProcess *>(appProcess, "_bksProcess");
		if (appBKSProcess) {
			[appProcess processWillExpire:appBKSProcess];
		}
	}
}

static void call_WhatsApp() {

	[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.mobilesms.notification" suspended:YES];
	[[FBProcessManager sharedInstance] createApplicationProcessForBundleID:@"com.apple.mobilesms.notification"];

	[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"net.whatsapp.WhatsApp" suspended:YES];
    [[FBProcessManager sharedInstance] createApplicationProcessForBundleID:@"net.whatsapp.WhatsApp"];

	static BKSProcessAssertion *insomnia;
	static BKSProcessAssertion *insomnia2;
	if (insomnia != nil) {
		[insomnia invalidate];
	}
	if (insomnia2 != nil) {
		[insomnia2 invalidate];
	}
	insomnia = [[BKSProcessAssertion alloc] initWithPID:[(SBApplication *)[[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:@"net.whatsapp.WhatsApp"] pid] flags:(ProcessAssertionFlagPreventSuspend | ProcessAssertionFlagAllowIdleSleep | ProcessAssertionFlagPreventThrottleDownCPU | ProcessAssertionFlagWantsForegroundResourcePriority) reason:10006 name:@"epichax1" withHandler:nil];
	insomnia2 = [[BKSProcessAssertion alloc] initWithPID:[(SBApplication *)[[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:@"com.apple.mobilesms.notification"] pid] flags:(ProcessAssertionFlagPreventSuspend | ProcessAssertionFlagAllowIdleSleep | ProcessAssertionFlagPreventThrottleDownCPU | ProcessAssertionFlagWantsForegroundResourcePriority) reason:10006 name:@"epichax2" withHandler:nil];
}

@implementation WAQuickReplyMessage
@end


%group mainSB

// testing
static NSString *getMyString(NSDictionary *dict, id key, NSString *fallback) {
    id result = [dict objectForKey: key];

    if (!result) {
        result = fallback;
    } else if (![result isKindOfClass: [NSString class]]) {
        result = [result description];
        if ([result isEqualToString:@"<null>"]) {
            result = fallback;
        }
    }

    return result;
}

static NSString *getUserJidFromBulletin(BBBulletinRequest *bulletin) {
    NSMutableDictionary *messageData;
    NSDictionary *remoteNcDict = [bulletin.context objectForKey:@"remoteNotification"];
    if ([bulletin.context objectForKey:@"localNotification"] != nil)
    {
        UIConcreteLocalNotification *gold = (UIConcreteLocalNotification *)[NSKeyedUnarchiver unarchiveObjectWithData:[bulletin.context objectForKey:@"localNotification"]];
        messageData = [[gold userInfo] mutableCopy];
    } else {
        messageData = [NSMutableDictionary new];
        NSString *jid = nil;
        NSString *u = remoteNcDict[@"aps"][@"u"];

        if ([u rangeOfString:@"-"].location == NSNotFound) {
            jid = [NSString stringWithFormat:@"%@@s.whatsapp.net", u];
        } else {
            jid = [NSString stringWithFormat:@"%@@g.us", u];
        }
        [messageData setObject:jid forKey:@"jid"];
    }
    NSDictionary *mData = [messageData copy];
    NSString *lastJID = mData[@"jid"];
    if ([lastJID isEqualToString:@"(null)@g.us"] || [lastJID isEqualToString:@"(null)@s.whatsapp.net"]) {
        return nil;
    }
    
    return lastJID;
}

static UIImage *userImageFromJID(NSString *userJID) {
    UIImage *profileImage = nil;
    NSDictionary *appInfoGet = [WAQuickReply2Helper getAppInfoFromAppID:@"net.whatsapp.WhatsApp"];
    NSString *bundPath = [appInfoGet objectForKey:@"SHARED_PATH"];
    NSString *dataPath = [appInfoGet objectForKey:@"DATA_PATH"];
    NSString *appPathBundle = [appInfoGet objectForKey:@"APP_PATH"];
    NSString *profilePicPath = [NSString stringWithFormat:@"%@/Library/Caches/ProfilePictures", dataPath];
    NSArray *whatsIDs = [userJID componentsSeparatedByString:@"@"];
    NSString *whatsID = [whatsIDs firstObject];

    NSString *contactsDBPath = [bundPath stringByAppendingPathComponent:@"Contacts.sqlite"];
    NSString *chatsDBPath = [bundPath stringByAppendingPathComponent:@"ChatStorage.sqlite"];

    if ([userJID hasSuffix:@"@g.us"]) {
        NSArray *groupInfo = [WAQuickReply2Helper getMessagesFromDataBase:chatsDBPath fromSelectQuery:[NSString stringWithFormat:@"SELECT * FROM ZWAGROUPINFO"]];
        for (NSDictionary *group in groupInfo) {
            if ([group isKindOfClass:[NSDictionary class]]) {
                id picPathZ = group[@"ZPICTUREPATH"];
                if ([picPathZ isKindOfClass:[NSNull class]]) {
                    profileImage = [UIImage imageNamed:@"GroupChatRound" inBundle:whatsAppBundle()];
                } else if ([picPathZ isKindOfClass:[NSString class]]) {
                    if ([picPathZ containsString:whatsID]) {
                        NSString *picPath = [WAQuickReply2Helper MD5String:userJID];
                        NSString *mediaProfilePathFull = [NSString stringWithFormat:@"%@/pp_%@.profile.jpg", profilePicPath, picPath];
                        NSData *imageData = [NSData dataWithContentsOfFile:mediaProfilePathFull];
                        if (imageData) {
                            profileImage = [UIImage imageWithData:imageData];
                        } else {
                            profileImage = [UIImage imageNamed:@"GroupChatRound" inBundle:whatsAppBundle()]; //[UIImage imageWithData:persoImageData];
                        }   
                    }
                }
            }
        }
    } else {
        NSArray *usersStatus = [WAQuickReply2Helper getMessagesFromDataBase:contactsDBPath fromSelectQuery:[NSString stringWithFormat:@"SELECT * FROM ZWASTATUS"]];
        for (NSDictionary *userStatus in usersStatus) {
            if ([userStatus isKindOfClass:[NSDictionary class]]) {
                id picPathZ = userStatus[@"ZPICTUREPATH"];
                if ([picPathZ isKindOfClass:[NSNull class]]) {
                    profileImage = [UIImage imageNamed:@"PersonalChatRound" inBundle:whatsAppBundle()];
                } else if ([picPathZ isKindOfClass:[NSString class]]) {
                    NSString *userJIDZ = userStatus[@"ZWHATSAPPID"];
                    if ([userJIDZ isEqualToString:whatsID]) {
                        NSString *picPath = [WAQuickReply2Helper MD5String:userJID];
                        NSString *mediaProfilePathFull = [NSString stringWithFormat:@"%@/pp_%@.profile.jpg", profilePicPath, picPath];
                        NSData *imageData = [NSData dataWithContentsOfFile:mediaProfilePathFull];
                        if (imageData) {
                            profileImage = [UIImage imageWithData:imageData];
                        } else {
                            profileImage = [UIImage imageNamed:@"PersonalChatRound" inBundle:whatsAppBundle()]; //[UIImage imageWithData:persoImageData];
                        }   
                    }
                }
            }
        }
    }

    profileImage = [WAQuickReply2Helper imageByScaling:profileImage toSize:CGSizeMake(70,70)];

    return [WAQuickReply2Helper makeRoundedImage:profileImage radius:36];
}

static NSString *userNameFromJID(NSString *userJID) {
    NSDictionary *appInfoGet = [WAQuickReply2Helper getAppInfoFromAppID:@"net.whatsapp.WhatsApp"];
    NSString *bundPath = [appInfoGet objectForKey:@"SHARED_PATH"];
    NSString *chatsDBPath = [bundPath stringByAppendingPathComponent:@"ChatStorage.sqlite"];

    if ([userJID hasSuffix:@"@g.us"]) {

    }
    NSString *userName = [WAQuickReply2Helper getStringFromDataBase:chatsDBPath andColumnName:@"ZPARTNERNAME" fromSelectQuery:[NSString stringWithFormat:@"SELECT * FROM ZWACHATSESSION WHERE ZCONTACTJID = '%@'", userJID]];
    return userName;
}

static NSMutableArray *getAllUsersFromChats(NSString *keyword) {

    NSDictionary *appInfoGet = [WAQuickReply2Helper getAppInfoFromAppID:@"net.whatsapp.WhatsApp"];
    NSString *bundPath = [appInfoGet objectForKey:@"SHARED_PATH"];
    NSString *chatsDBPath = [bundPath stringByAppendingPathComponent:@"ChatStorage.sqlite"];

    NSArray *allChatsContacts = nil;
    NSMutableArray *contacts = [NSMutableArray array];
    if (keyword.length == 0) {
        allChatsContacts = [WAQuickReply2Helper getMessagesFromDataBase:chatsDBPath fromSelectQuery:@"SELECT * FROM ZWACHATSESSION"];
        for (NSDictionary *chatSessions in allChatsContacts) {
            if ([chatSessions isKindOfClass:[NSDictionary class]]) {
                [contacts addObject:chatSessions[@"ZCONTACTJID"]];
            }
        }
    } 
    else {
        allChatsContacts = [WAQuickReply2Helper getMessagesFromDataBase:chatsDBPath fromSelectQuery:@"SELECT * FROM ZWACHATSESSION"];
        for (NSDictionary *chatSessions in allChatsContacts) {
            if ([chatSessions isKindOfClass:[NSDictionary class]]) {
                NSString *partnerName = chatSessions[@"ZPARTNERNAME"];
                NSString *contactJid = chatSessions[@"ZCONTACTJID"];
                if ([partnerName rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound || [contactJid rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    [contacts addObject:contactJid];
                }
            } else {

            }
        }
    }

    return contacts;
}

static NSMutableArray *getUserChatMessages(NSString *userJID) {

    call_WhatsApp();
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.imokhles.waquickreply.sender" object:nil userInfo:nil]; // fake message to wake-up the app before real message
    NSMutableArray *messagesMutable = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *appInfoGet = [WAQuickReply2Helper getAppInfoFromAppID:@"net.whatsapp.WhatsApp"];
    NSString *bundPath = [appInfoGet objectForKey:@"SHARED_PATH"];
    NSString *chatsDBPath = [bundPath stringByAppendingPathComponent:@"ChatStorage.sqlite"];
    NSString *dataPath = [appInfoGet objectForKey:@"DATA_PATH"];
    NSString *libraryPath = [NSString stringWithFormat:@"%@/Library", dataPath];

    NSArray *allChatsContacts = [WAQuickReply2Helper getMessagesFromDataBase:chatsDBPath fromSelectQuery:@"SELECT * FROM ZWACHATSESSION"];
    NSMutableArray *allMessagesMedia = [WAQuickReply2Helper getMessagesFromDataBase:chatsDBPath fromSelectQuery:@"SELECT * FROM ZWAMEDIAITEM"];

    for (NSDictionary *chatSessions in allChatsContacts) {
        if ([chatSessions isKindOfClass:[NSDictionary class]]) {
            NSString *userJIDZ = chatSessions[@"ZCONTACTJID"];
            if ([userJIDZ isEqualToString:userJID]) {
                NSArray *allMessages = [WAQuickReply2Helper getMessagesFromDataBase:chatsDBPath fromSelectQuery:[NSString stringWithFormat:@"SELECT * FROM ZWAMESSAGE"]];

                if (allMessages > 0) {
                    NSMutableArray *waMessagesArray = [NSMutableArray array];
                    for (NSDictionary *message in allMessages) {
                        NSNumber *chatSession = message[@"ZCHATSESSION"];
                        NSNumber *chatZ_PK = chatSessions[@"Z_PK"];
                        if (chatSession != chatZ_PK) {
                            continue;
                        }
                        NSString *isFromJID = message[@"ZFROMJID"];
                        NSString *text = message[@"ZTEXT"];
                        NSNumber *isFromMe = message[@"ZISFROMME"];
                        NSNumber *messageType = message[@"ZMESSAGETYPE"];
                        NSNumber *groupEventType = message[@"ZGROUPEVENTTYPE"];
                        NSNumber *groupMember = message[@"ZGROUPEVENTTYPE"];
                        NSNumber *chatSessionNumber = message[@"ZCHATSESSION"];
                        NSString *dateUnixString = message[@"ZMESSAGEDATE"];

                        double unixTimeStamp = [dateUnixString doubleValue];
                        NSTimeInterval _interval=unixTimeStamp;
                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
                        // NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
                        // [_formatter setLocale:[NSLocale currentLocale]];
                        // [_formatter setDateFormat:@"dd.MM.yyyy"];
                        // NSString *_date = [_formatter stringFromDate:date];

                        WAQuickReplyMessage *waMessage = [[WAQuickReplyMessage alloc] init];
                        switch(messageType.integerValue) {
                            case 0: {
                                // text message
                                if ([userJID hasSuffix:@"@g.us"]) {
                                    // group
                                    NSString *contactName = [WAQuickReply2Helper getStringFromDataBase:chatsDBPath andColumnName:@"ZCONTACTNAME" fromSelectQuery:[NSString stringWithFormat:@"SELECT * FROM ZWAGROUPMEMBER WHERE ZCHATSESSION = '%@'", chatSessionNumber]];
                                    waMessage.content = [NSString stringWithFormat:@"%@: %@", contactName, text];
                                } else {
                                    waMessage.content = text;
                                }
                                break;
                            }
                            case 1: {
                                // photo message
                                for (NSDictionary *mediaItem in allMessagesMedia) {
                                    NSNumber *mediaItemNM = message[@"ZMEDIAITEM"];
                                    NSNumber *mediaItemZ_PK = mediaItem[@"Z_PK"];
                                    if (mediaItemNM != mediaItemZ_PK) {
                                        continue;
                                    }
                                    NSString *mediaPathInLibrary = mediaItem[@"ZMEDIALOCALPATH"];//[allMessagesMedia objectAtIndex:0];
                                    NSLog(@"********** %@", mediaPathInLibrary);
                                    if ([userJID hasSuffix:@"@g.us"]) {
                                        // group
                                        NSString *contactName = [WAQuickReply2Helper getStringFromDataBase:chatsDBPath andColumnName:@"ZCONTACTNAME" fromSelectQuery:[NSString stringWithFormat:@"SELECT * FROM ZWAGROUPMEMBER WHERE ZCHATSESSION = '%@'", chatSessionNumber]];
                                        
                                        if (!mediaPathInLibrary) {
                                            waMessage.content = @"[Media Path Not Found]";
                                        } else {
                                            waMessage.content = [NSString stringWithFormat:@"%@: %@", contactName, @"groups images doesn's support"];
                                        }
                                    } else {
                                        if (!mediaPathInLibrary) {
                                            waMessage.content = @"[Media Path Not Found]";
                                        } else {
                                            NSString *mediaPath = [NSString stringWithFormat:@"%@/%@", libraryPath, mediaPathInLibrary];
                                            if ([fileManager fileExistsAtPath:mediaPath]) {
                                                waMessage.content = [NSURL fileURLWithPath:mediaPath];
                                            } else {
                                                waMessage.content = @"[Media Not Downloaded]";
                                            }
                                        }
                                    }
                                }
                                break;
                            }
                            case 2: {
                                // Video message
                                for (NSDictionary *mediaItem in allMessagesMedia) {
                                    NSString *mediaPathInLibrary = mediaItem[@"ZMEDIALOCALPATH"];//[allMessagesMedia objectAtIndex:0];
                                    if ([userJID hasSuffix:@"@g.us"]) {
                                        // group
                                        NSString *contactName = [WAQuickReply2Helper getStringFromDataBase:chatsDBPath andColumnName:@"ZCONTACTNAME" fromSelectQuery:[NSString stringWithFormat:@"SELECT * FROM ZWAGROUPMEMBER WHERE ZCHATSESSION = '%@'", chatSessionNumber]];
                                        

                                        if (!mediaPathInLibrary) {
                                            waMessage.content = @"[Media Path Not Found]";
                                        } else {
                                            waMessage.content = [NSString stringWithFormat:@"%@: %@", contactName, @"groups video doesn's support"];
                                        }
                                    } else {
                                        if (!mediaPathInLibrary) {
                                            waMessage.content = @"[Media Path Not Found]";
                                        } else {
                                            NSString *mediaPath = [NSString stringWithFormat:@"%@/%@", libraryPath, mediaPathInLibrary];
                                            if ([fileManager fileExistsAtPath:mediaPath]) {
                                                waMessage.content = [NSURL fileURLWithPath:mediaPath];
                                            } else {
                                                waMessage.content = @"[Media Not Downloaded]";
                                            }
                                        }
                                    }
                                }
                                break;
                            }
                        }
                        waMessage.timestamp = date;
                        waMessage.outgoing = isFromMe.boolValue;
                        [waMessagesArray insertObject:waMessage atIndex:0];
                    }
                    messagesMutable = [[NSMutableArray alloc] initWithArray:waMessagesArray];
                }
            }
        } else {
            
        }   
    }
    NSArray* reversedArray = [[messagesMutable reverseObjectEnumerator] allObjects];
    return reversedArray;
}

@implementation WAQuickReplyHandler
+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (NSString *)getUserIdentifier:(BBBulletin *)bulletin {
    return getUserJidFromBulletin(bulletin);
}

- (NSString *)getNickname:(NSString *)userIdentifier {
    return userNameFromJID(userIdentifier);
}

- (UIImage *)getAvatar:(NSString *)userIdentifier {
    return userImageFromJID(userIdentifier);
}

- (NSArray *)getContacts:(NSString *)keyword {
    return getAllUsersFromChats(keyword);
}

- (NSArray *)getMessages:(NSString *)userIdentifier {
    return getUserChatMessages(userIdentifier);
}

- (void)sendMessage:(id<CouriaMessage>)message toUser:(NSString *)userIdentifier {
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.imokhles.waquickreply.sender" object:nil userInfo:nil];
	WAQuickReplyMessage *waMessage = [[WAQuickReplyMessage alloc] init];
    waMessage.content = message.content;
    waMessage.outgoing = message.outgoing;
    waMessage.timestamp = message.timestamp;

    NSMutableDictionary *messageDict = [NSMutableDictionary new];
    [messageDict setObject:userIdentifier forKey:@"jid"];
    call_WhatsApp();

    if ([waMessage.content isKindOfClass:NSURL.class]) {
        NSURL *fileURL = waMessage.content;
        NSLog(@"********* MIMETYPE: %@", [fileURL pathExtension]);
        if ([WAQuickReply2Helper handleImageExtension:[fileURL pathExtension]]) {
            // [messageDict setObject:@1 forKey:@"isURL"];
            NSData *urlData = [NSData dataWithContentsOfURL:fileURL];
            UIImage *imageQr = [[UIImage alloc] initWithData:urlData];
            NSData *imageData = UIImageJPEGRepresentation(imageQr, 0.2);

            // send to documents path
            NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
            NSString *docDirPath=[pathArray objectAtIndex:0];
            NSString *writePath=[docDirPath stringByAppendingPathComponent:@"waqImage.jpg"];

            NSDictionary *appInfoGet = [WAQuickReply2Helper getAppInfoFromAppID:@"net.whatsapp.WhatsApp"];
            NSString *dataPath = [appInfoGet objectForKey:@"DATA_PATH"];
            NSString *newPath = [dataPath stringByAppendingPathComponent:@"Documents/waqImage.jpg"];
            if (isThisFileExiste([newPath UTF8String])) {
                [[IMClient sharedInstance] deleteFile:newPath];
            }

            // send to whatsapp
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (![imageData writeToFile:writePath atomically:YES]) {
                    // failure
                    NSLog(@">>>>>>>>>>>>> %@", newPath);        
                    NSLog(@"FAILEEEEEEEEED");
                } 
                [[IMClient sharedInstance] moveFile:writePath toFile:newPath];
                [messageDict setObject:newPath forKey:@"mediaPath"];
                NSDictionary *mData = [messageDict copy];
                [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.imokhles.waquickreply.sendimage" object:nil userInfo:mData];
            });
        } else if ([WAQuickReply2Helper handleVideoExtension:[fileURL pathExtension]]) {
            NSLog(@"********************** VIDEO");
            // [messageDict setObject:newPath forKey:@"mediaPath"];
            // NSDictionary *mData = [messageDict copy];
            // [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.imokhles.waquickreply.sendvideo" object:nil userInfo:mData];
        }
        
    } else {
        // [messageDict setObject:@0 forKey:@"isURL"];
        [messageDict setObject:waMessage.content forKey:@"contentMSG"];
        NSDictionary *userInfo = [messageDict copy];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.imokhles.waquickreply.sender" object:nil userInfo:userInfo];
    }
    // testing
    // [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CouriaConversationViewRefreshNotification" object:nil userInfo:nil];
}

- (void)markRead:(NSString *)userIdentifier {
    // [WAQuickReply2Helper markAsReadChatSessionForJID:userIdentifier];
}

- (BOOL)canSendPhotos {
    return YES;
}

- (BOOL)shouldClearNotifications {
    return YES;
}
@end
%ctor
{
    if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"]) {
        Couria *couria = [NSClassFromString(@"Couria") sharedInstance];
        WAQuickReplyHandler *waqrhandler = [WAQuickReplyHandler sharedInstance];
        [couria registerExtension:waqrhandler forApplication:@"net.whatsapp.WhatsApp"];
    }
}
%end

%group mainWA

// Hooks
WAChatStorage *storage;
WAChatSession *chat;
XMPPConnection *xmConnection;

// anti-jailbreak
%hook WASharedAppData
+ (void)showLocalNotificationForJailbrokenPhoneAndTerminate {
    return;
}
%end

// start communication
%hook ChatManager
-(id)init {

    id chatManager = %orig;
    storage = [objc_getClass("WASharedAppData") chatStorage];
    xmConnection = [%c(WASharedAppData) xmppConnection];
    return chatManager;
}
%end

@interface WAQuickReplySender : NSObject
+ (id)sharedSender;
- (void)startSender;
- (void)sendMessage:(WAQuickReplyMessage *)message forJID:(NSString *)userJID;
- (void)sendMessageText:(NSString *)message forJID:(NSString *)userJID;
@end

@implementation WAQuickReplySender
+ (id)sharedSender {
	static id sharedSender = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSender = [[self alloc] init];
    });
    return sharedSender;
}
- (void)startSender {
    // com.imokhles.waquickreply.sendimage
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(waquickreply_notification:) name:@"com.imokhles.waquickreply.sendvideo" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(waquickreply_notification:) name:@"com.imokhles.waquickreply.sendimage" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(waquickreply_notification:) name:@"com.imokhles.waquickreply.sender" object:nil];
}

- (void)waquickreply_notification:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
    NSString *jid = [userInfo objectForKey:@"jid"];
    // BOOL isURL = [[userInfo objectForKey:@"isURL"] boolValue];
    id msgContent = [userInfo objectForKey:@"contentMSG"];
    id mediaPath = [userInfo objectForKey:@"mediaPath"];
    if ([notification.name isEqualToString:@"com.imokhles.waquickreply.sendimage"]) {
        [self sendImageMessageFromPath:mediaPath forJID:jid];
    } else if ([notification.name isEqualToString:@"com.imokhles.waquickreply.sender"]) {
        [self sendMessageText:(NSString *)msgContent forJID:jid];
    } else if ([notification.name isEqualToString:@"com.imokhles.waquickreply.sendvideo"]) {
        [self sendVideoMessageFromPath:mediaPath forJID:jid];
    }
    
}

- (void)sendImageMessageFromPath:(NSString *)urlMessage forJID:(NSString *)userJID {
    chat = [storage newOrExistingChatSessionForJID:userJID];
    NSString *writePath= urlMessage; //[docDirPath stringByAppendingPathComponent:@"waqImage.jpg"];
    UIImage *imageToSend = [UIImage imageWithContentsOfFile:writePath];
    [storage sendMessageWithImage:imageToSend caption:@" " inChatSession:chat completion: ^{
    
    }];
}

- (void)sendVideoMessageFromPath:(NSString *)urlMessage forJID:(NSString *)userJID {
    chat = [storage newOrExistingChatSessionForJID:userJID];
    NSString *writePath= urlMessage; //[docDirPath stringByAppendingPathComponent:@"waqImage.jpg"];
    [storage sendVideoAtURL:[NSURL fileURLWithPath:writePath] caption:@" " collectionID:nil index:0 count:0 inChatSession:chat completion: ^{

    }];
}

- (void)sendMessageText:(NSString *)message forJID:(NSString *)userJID {
	NSLog(@"************ WAQuickReplyMessage: %@", message);
	// close_WhatsApp();
	chat = [storage newOrExistingChatSessionForJID:userJID];
    if (WAQuickReplyAppVersionGreaterThanOrEqualTo(@"2.12.5")) {
        [storage sendMessageWithText:(NSString *)message metadata:nil inChatSession:chat];
    } else {
        [storage sendMessageWithText:(NSString *)message inChatSession:chat];
    }
}

-(void)createTestLocalNotification {
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    notification.alertBody = @"Test Message";
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    NSDictionary *userDict = [NSDictionary dictionaryWithObject:@"273654234@s.whatsapp.net"
                                                forKey:@"jid"];
    notification.userInfo = userDict;
    // notification.applicationIconBadgeNumber = 10;

    UIApplication *currentApp = [UIApplication sharedApplication];
    [currentApp presentLocalNotificationNow:notification];
    
}

@end

%hook WhatsAppAppDelegate
- (void)loadApplicationUI {
    %orig;
    // [[WAQuickReplySender sharedSender] createTestLocalNotification];
}
%end

%ctor {
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"WhatsApp"]) {
		[[WAQuickReplySender sharedSender] startSender];
	}
}
%end

%group iOS8Enti
static int (*orig_BSAuditTokenTaskHasEntitlement)(id connection, NSString *entitlement);
static int new_wa_BSAuditTokenTaskHasEntitlement(id connection, NSString *entitlement)
{
    if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"WhatsApp"] && [entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
        return true;
    } else if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && [entitlement isEqualToString:@"com.apple.frontboard.launchapplications"]) {
        return true;
    } else {
        return orig_BSAuditTokenTaskHasEntitlement(connection, entitlement);
    }
}
%end

%group iOS9Enti
static int (*orig_BSXPCConnectionHasEntitlement)(id connection, NSString *entitlement);
static int new_wa_BSXPCConnectionHasEntitlement(id connection, NSString *entitlement)
{
    if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"WhatsApp"] && [entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
        return true;
    } else if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && [entitlement isEqualToString:@"com.apple.frontboard.launchapplications"]) {
        return true;
    } else {
        return orig_BSXPCConnectionHasEntitlement(connection, entitlement);
    }
}
%end

%ctor {
	@autoreleasepool {
		%init();
		if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"WhatsApp"]) {
			%init(mainWA);
		} else if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"]) {
				%init(mainSB);
		} else if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"assertiond"]) {
	        dlopen("/System/Library/PrivateFrameworks/XPCObjects.framework/XPCObjects", RTLD_LAZY);

	        if (IS_OS_9_OR_LATER) {
	            %init(iOS9Enti);
	            void *xpcFunction = MSFindSymbol(NULL, "_BSXPCConnectionHasEntitlement");
	            MSHookFunction(xpcFunction, (void *)new_wa_BSXPCConnectionHasEntitlement, (void **)&orig_BSXPCConnectionHasEntitlement);
	        } else {
	            %init(iOS8Enti);
	            void *xpcFunction = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
	            MSHookFunction(xpcFunction, (void *)new_wa_BSAuditTokenTaskHasEntitlement, (void **)&orig_BSAuditTokenTaskHasEntitlement);
	        }
	    }
	}
}
