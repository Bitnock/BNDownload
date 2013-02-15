//
//  BNDownloadManager.m
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/13.
//  Copyright (c) 2013 Bitnock. All rights reserved.
//

#import "BNDownloadManager.h"

#import "BNHTTPDownload.h"

@implementation BNDownloadManager

static BNDownloadManager* sharedManager;

+ (BNDownloadManager*)sharedManager {
  @synchronized(self) {
    if (!sharedManager) {
      sharedManager = self.new;
    }
  }
  
  return sharedManager;
}

- (void)addOperation:(BNHTTPDownload*)download {
  if (![self downloadInQueueWithURL:download.request.URL]) {
    [self registerAsObserverForDownload:download];
    [super addOperation:download];
  }
}

- (BNHTTPDownload*)downloadInQueueWithURL:(NSURL*)url {
  for (BNHTTPDownload* download in self.operations) {
    if ([download.request.URL isEqual:url]) {
      return download;
    }
  }
  
  return nil;
}

#pragma mark - Download Observer

- (void)registerAsObserverForDownload:(BNHTTPDownload*)download {
  [download addObserver:self];
}

- (void)unregisterAsObserverForDownload:(BNHTTPDownload*)download {
  [download removeObserver:self];
}

- (IBAction)observedDownloadDidStart:(BNHTTPDownload*)download {
  
}

- (IBAction)observedDownloadDidProgress:(BNHTTPDownload*)download {
  
}

- (IBAction)observedDownloadDidEnd:(BNHTTPDownload*)download {
  
}

@end
