//
//  BNDownloadManager.h
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/13.
//  Copyright (c) 2013 Bitnock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BNDownloadObserver.h"

@class BNHTTPDownload;

@interface BNDownloadManager : NSOperationQueue <BNDownloadObserver>

+ (BNDownloadManager*)sharedManager;

- (void)addOperation:(BNHTTPDownload*)download;

- (BNHTTPDownload*)downloadInQueueWithURL:(NSURL*)url;

@end
