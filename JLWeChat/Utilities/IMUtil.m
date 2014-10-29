//
//  IMUtil.m
//  JLWeChat
//
//  Created by jimneylee on 14-10-25.
//  Copyright (c) 2014年 jimneylee. All rights reserved.
//

#import "IMUtil.h"
#import "AFHTTPRequestOperation.h"
#import "QiniuSDK.h"
#import "QNAuthPolicy.h"
#import "IMCache.h"

@implementation IMUtil

+ (NSString *)generateImageTimeKey
{
    NSString *timeString = [IMUtil generateTimeKey];
    return [NSString stringWithFormat:@"%@.jpg", timeString];
}

+ (NSString *)generateVoiceTimeKey
{
    NSString *timeString = [IMUtil generateTimeKey];
    return [NSString stringWithFormat:@"%@.voice", timeString];
}

+ (NSString *)generateTimeKey
{
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    [f setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSString *timeString = [f stringFromDate:[NSDate date]];
    return timeString;
}

+ (void)uploadFileWithUrlkey:(NSString *)urlkey
               completeBlock:(void (^)(BOOL success,  NSString *key))completeBlock
{
    NSString *token = [QNAuthPolicy defaultToken];
	QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil progressHandler:nil
                                                        params:nil checkCrc:YES cancellationSignal:nil];
    QNUploadManager *upManager = [QNUploadManager sharedInstanceWithRecorder:nil recorderKeyGenerator:nil];
    NSData *data = [[IMCache sharedCache] cachedDataForUrlKey:urlkey];
	[upManager putData:data key:urlkey
                 token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                     // TODO:check success with status code
                     if (info.statusCode) {
                         
                     }
                     completeBlock(YES, key);
                 } option:opt];
}

+ (void)downloadFileWithUrl:(NSString*)url
              progressBlock:(void (^)(CGFloat progress))progressBlock
              completeBlock:(void (^)(BOOL success, NSError *error))completeBlock
{
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    
    NSString *fileName = [url lastPathComponent];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:fileName];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:filePath append:NO]];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"download progress = %f", (float)totalBytesRead / totalBytesExpectedToRead);
        progressBlock((float)totalBytesRead / totalBytesExpectedToRead);
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        completeBlock(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completeBlock(NO, error);
    }];
    
    [operation start];
}

@end
