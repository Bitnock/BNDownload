//
//  BNDownloadManager.m
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/2013.
//  Copyright (c) 2013 Bitnock.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "BNDownloadManager.h"

#import "BNHTTPDownload.h"

NSString * const BNDownloadManagerOperationCountContext = @"BNDownloadManagerOperationCountContext";

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

- (void)observedDownloadDidStart:(BNHTTPDownload*)download {

}

- (void)observedDownloadDidProgress:(BNHTTPDownload*)download {

}

- (void)observedDownloadDidEnd:(BNHTTPDownload*)download {

}

@end
