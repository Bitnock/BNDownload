//
//  BNHTTPDownload_private.h
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/13.
//  Copyright (c) 2013 Bitnock. All rights reserved.
//

#import "BNHTTPDownload.h"

#import <CommonCrypto/CommonDigest.h>

@interface BNHTTPDownload () {
  long long _totalBytesRead;
  long long _totalBytesExpectedToRead;
}

@property (nonatomic, strong) NSSet* observers;

- (void)didProgress:(NSUInteger)bytesRead total:(long long)totalBytesRead expected:(long long)totalBytesExpectedToRead;
- (void)didGetCanceled;
- (void)didSucceed:(id)responseObject;
- (void)didFail:(NSError*)error;
- (void)didEnd;

- (BOOL)isBeingObservedBy:(id<BNDownloadObserver>)object;

- (void)messageObserversForOperationStart;
- (void)messageObserversForOperationProgress;
- (void)messageObserversForOperationEnd;

@end
