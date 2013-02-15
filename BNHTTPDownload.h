//
//  BNDownload.h
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/13.
//  Copyright (c) 2013 Bitnock. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

#import "BNDownloadObserver.h"

@interface BNHTTPDownload : AFHTTPRequestOperation

+ (id)downloadWithURL:(NSURL*)url progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;
+ (id)downloadWithURL:(NSURL*)url;

@property (nonatomic, strong, readonly) NSURLRequest* request;
@property (nonatomic, readonly) double progress;

- (id)initWithURL:(NSURL*)url progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

@property (nonatomic, strong, readonly) NSString* outputStreamPath;
@property (nonatomic, strong, readonly) NSString* destinationPath;

- (void)addObserver:(id<BNDownloadObserver>)observer;
- (void)removeObserver:(id<BNDownloadObserver>)observer;

@end
