//
//  BNDownloadObserver.h
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/13.
//  Copyright (c) 2012 Bitnock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class BNHTTPDownload;

@protocol BNDownloadObserver <NSObject>

@required

- (void)registerAsObserverForDownload:(BNHTTPDownload*)download;
- (void)unregisterAsObserverForDownload:(BNHTTPDownload*)download;

@optional

- (IBAction)observedDownloadDidStart:(BNHTTPDownload*)download;
- (IBAction)observedDownloadDidProgress:(BNHTTPDownload*)download;
- (IBAction)observedDownloadDidEnd:(BNHTTPDownload*)download;

@end