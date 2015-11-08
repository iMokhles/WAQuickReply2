//
//  WAQuickReply2ListController.m
//  WAQuickReply2
//
//  Created by iMokhles on 29.10.2015.
//  Copyright (c) 2015 iMokhles. All rights reserved.
//

#import "WAQuickReply2Helper.h"

// extern WAContactsStorage *contactsStorage;
// extern WAChatStorage *chatStorage;
// extern WAProfilePictureManager *profilePictureManager;

// - - - - 

@implementation NSString ( containsCategory )

- (BOOL) containsString: (NSString*) substring
{    
    NSRange range = [self rangeOfString : substring];
    BOOL found = ( range.location != NSNotFound );
    return found;
}

@end

@implementation WAQuickReply2Helper

// Preferences
+ (NSString *)preferencesPath {
	return @"/User/Library/Preferences/com.imokhles.waquickreply2.plist";
}

+ (CFStringRef)preferencesChanged {
	return (__bridge CFStringRef)@"com.imokhles.waquickreply2.preferences-changed";
}

// UIWindow to present your elements
// u can show/hide it using ( setHidden: NO/YES )
+ (UIWindow *)mainWAQuickReply2Window {
	return nil;
}

+ (UIViewController *)mainWAQuickReply2ViewController {
	return nil;
}

// Checking App Version
+ (BOOL)isAppVersionGreaterThanOrEqualTo:(NSString *)appversion {
	return [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] compare:appversion options:NSNumericSearch] != NSOrderedAscending;
}
+ (BOOL)isAppVersionLessThanOrEqualTo:(NSString *)appversion {
	return [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] compare:appversion options:NSNumericSearch] != NSOrderedDescending;
}

// Checking OS Version
+ (BOOL)isIOS83_OrGreater {
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.3;
}
+ (BOOL)isIOS80_OrGreater {
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0;
}
+ (BOOL)isIOS70_OrGreater {
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
}
+ (BOOL)isIOS60_OrGreater {
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0;
}
+ (BOOL)isIOS50_OrGreater {
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0;
}
+ (BOOL)isIOS40_OrGreater {
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0;
}

// Checking Device Type
+ (BOOL)isIPhone6_Plus {
	return [self isIPhone] && [self screenMaxLength] == 736.0;
}
+ (BOOL)isIPhone6 {
	return [self isIPhone] && [self screenMaxLength] == 667.0;
}
+ (BOOL)isIPhone5 {
	return [self isIPhone] && [self screenMaxLength] == 568.0;
}
+ (BOOL)isIPhone4_OrLess {
	return [self isIPhone] && [self screenMaxLength] < 568.0;
}

// Checking Device Interface
+ (BOOL)isIPad {
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}
+ (BOOL)isIPhone {
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

// Checking Device Retina
+ (BOOL)isRetina {
	if ([self isIOS80_OrGreater]) {
        return [UIScreen mainScreen].nativeScale>=2;
    }
	return [[UIScreen mainScreen] scale] >= 2.0;
}

// private methods

+ (NSDictionary *)getAppInfoFromAppID:(NSString *)appIdentifier {
	if (kCFCoreFoundationVersionNumber < 1140.10) {
        NSDictionary *mobileInstallationPlist = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Caches/com.apple.mobile.installation.plist"];
        NSDictionary *installedAppDict = (NSDictionary*)[mobileInstallationPlist objectForKey:@"User"];

        NSDictionary *appInfo = [installedAppDict objectForKey:appIdentifier];
        if (appInfo) {
            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:8];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleIdentifier"]) forKey:@"APP_ID"];
            [info setObject:formatDictValue([appInfo objectForKey:@"Container"]) forKey:@"BUNDLE_PATH"];
            [info setObject:formatDictValue([appInfo objectForKey:@"Path"]) forKey:@"APP_PATH"];
            [info setObject:formatDictValue([appInfo objectForKey:@"Container"]) forKey:@"DATA_PATH"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleVersion"]) forKey:@"VERSION"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleShortVersionString"]) forKey:@"SHORT_VERSION"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleName"]) forKey:@"NAME"];
            [info setObject:formatDictValue([appInfo objectForKey:@"CFBundleDisplayName"]) forKey:@"DISPLAY_NAME"];
            return info;
        }
    } else {
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        if (LSApplicationWorkspace_class) {
            LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
            if (workspace && [workspace applicationIsInstalled:appIdentifier]) {
                Class LSApplicationProxy_class = objc_getClass("LSApplicationProxy");
                if (LSApplicationProxy_class) {
                    LSApplicationProxy *app = [LSApplicationProxy_class applicationProxyForIdentifier:appIdentifier];
                    if (app) {
                        // NSString *groupID = [app.groupIdentifiers objectAtIndex:0];
                        NSString *sharedPath = [app.groupContainers objectForKey:@"group.net.whatsapp.WhatsApp.shared"];
                        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:9];
                        [info setObject:formatDictValue(app.bundleIdentifier) forKey:@"APP_ID"];
                        [info setObject:formatDictValue([app.bundleContainerURL path]) forKey:@"BUNDLE_PATH"];
                        [info setObject:formatDictValue([app.bundleURL path]) forKey:@"APP_PATH"];
                        [info setObject:formatDictValue([app.dataContainerURL path]) forKey:@"DATA_PATH"];
                        [info setObject:formatDictValue(app.bundleVersion) forKey:@"VERSION"];
                        [info setObject:formatDictValue(app.shortVersionString) forKey:@"SHORT_VERSION"];
                        [info setObject:formatDictValue(app.localizedName) forKey:@"NAME"];
                        [info setObject:formatDictValue(sharedPath) forKey:@"SHARED_PATH"];
                        return info;
                    }
                }
            }
        }
    }
    return nil;
}

// Checking UIScreen sizes
+ (CGFloat)screenWidth {
	return [[UIScreen mainScreen] bounds].size.width;
}
+ (CGFloat)screenHeight {
	return [[UIScreen mainScreen] bounds].size.height;
}

+ (CGFloat)screenMaxLength {
    return MAX([self screenWidth], [self screenHeight]);
}

+ (CGFloat)screenMinLength {
    return MIN([self screenWidth], [self screenHeight]);
}

+ (BOOL)getBOOLFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery {
    BOOL newBOOL;

    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    FMResultSet *resultsWithNameLocation = [database executeQuery:selectQuery];
    while([resultsWithNameLocation next]) {
        /* taking results from database to a string "eleData" */
        newBOOL = (BOOL)[resultsWithNameLocation boolForColumn:columnName];
    }
    [database close];

    return newBOOL;
}
+ (long)getLongFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery {
    long newLong;

    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    FMResultSet *resultsWithNameLocation = [database executeQuery:selectQuery];
    while([resultsWithNameLocation next]) {
        /* taking results from database to a string "eleData" */
        newLong = (long)[resultsWithNameLocation longForColumn:columnName];
    }
    [database close];

    return newLong;
}
+ (double)getDoubleFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery {
    double newLong;

    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    FMResultSet *resultsWithNameLocation = [database executeQuery:selectQuery];
    while([resultsWithNameLocation next]) {
        /* taking results from database to a string "eleData" */
        newLong = (long)[resultsWithNameLocation doubleForColumn:columnName];
    }
    [database close];

    return newLong;
}
+ (NSDictionary *)getDictionaryFromDataBase:(NSString *)dataBasePath fromSelectQuery:(NSString *)selectQuery {
    NSDictionary *newDict = nil;

    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    FMResultSet *resultsWithNameLocation = [database executeQuery:selectQuery];
    while([resultsWithNameLocation next]) {
        /* taking results from database to a string "eleData" */
        newDict = (NSDictionary *)[resultsWithNameLocation resultDictionary];
    }
    [database close];

    return newDict;
}
+ (NSString *)getStringFromDataBase:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery {
    NSString *newString = nil;

    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    FMResultSet *resultsWithNameLocation = [database executeQuery:selectQuery];
    while([resultsWithNameLocation next]) {
        /* taking results from database to a string "eleData" */
        newString = [NSString stringWithFormat:@"%@",[resultsWithNameLocation stringForColumn:columnName]];
    }
    [database close];

    return newString;
}
+ (NSMutableArray *)getDataBaseInfo:(NSString *)dataBasePath andColumnName:(NSString *)columnName fromSelectQuery:(NSString *)selectQuery {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    FMResultSet *resultsWithNameLocation = [database executeQuery:selectQuery];
    while([resultsWithNameLocation next]) {
        /* taking results from database to a string "eleData" */
        NSString *getContent = [NSString stringWithFormat:@"%@",[resultsWithNameLocation stringForColumn:columnName]];
        [array addObject:getContent];
    }
    [database close];

    return array;
}

+ (NSArray *)getMessagesFromDataBase:(NSString *)dataBasePath fromSelectQuery:(NSString *)selectQuery {
    NSMutableArray *allMessages = [[NSMutableArray alloc] init];
    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    FMResultSet *resultsWithNameLocation = [database executeQuery:selectQuery];
    while([resultsWithNameLocation next]) {
        /* taking results from database to a string "eleData" */
        [allMessages addObject:[resultsWithNameLocation resultDictionary]];
    }
    [database close];

    return allMessages;
}

+ (BOOL)updateDataBase:(NSString *)dataBasePath withUpdateQuery:(NSString *)updateQuery {
    FMDatabase *database = [FMDatabase databaseWithPath:dataBasePath];
    [database open];
    [database setShouldCacheStatements:YES];

    BOOL result = [database executeUpdate:updateQuery];
    [database close];

    return result;
}

+ (NSString *)mimeTypeForFileAtPath:(NSString *)path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    // Borrowed from http://stackoverflow.com/questions/5996797/determine-mime-type-of-nsdata-loaded-from-a-file
    // itself, derived from  http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([path pathExtension]), NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return (__bridge NSString *)mimeType;
}

+ (NSString *)MD5String:(NSString *)string
{
    if(string == nil || [string length] == 0)
        return nil;
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    for(i=0;i<CC_MD5_DIGEST_LENGTH;i++)
    {
        [ms appendFormat: @"%02x", (int)(digest[i])];
    }
    return [ms copy];
}

+ (UIImage *)makeRoundedImage:(UIImage *) image radius: (float) radius;
{
  CALayer *imageLayer = [CALayer layer];
  imageLayer.frame = CGRectMake(0, 0, image.size.width, image.size.height);
  imageLayer.contents = (id) image.CGImage;

  imageLayer.masksToBounds = YES;
  imageLayer.cornerRadius = radius;

  UIGraphicsBeginImageContext(image.size);
  [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return roundedImage;
}

+ (UIImage *)imageByScaling:(UIImage *)image toSize:(CGSize)targetSize
{
    UIImage *sourceImage = image;
    UIImage *newImage = nil;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, [[UIScreen mainScreen] scale]);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"Could not scale image");
    
    return newImage;
}

+(BOOL)handleImageExtension:(NSString *)fileExt
{
    return ([fileExt isEqualToString:@"png"] || [fileExt isEqualToString:@"jpg"] || [fileExt isEqualToString:@"PNG"] || [fileExt isEqualToString:@"JPG"]);
}

+(BOOL)handleVideoExtension:(NSString *)fileExt
{
    return ([fileExt isEqualToString:@"mp4"] || [fileExt isEqualToString:@"m4v"] || [fileExt isEqualToString:@"mov"] || [fileExt isEqualToString:@"3gp"]);
}
@end
