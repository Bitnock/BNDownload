//
//  BNDownload.m
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/13.
//  Copyright (c) 2013 Bitnock. All rights reserved.
//

#import "BNHTTPDownload_private.h"

@interface BNHTTPDownload ()

- (void)setRequest:(NSURLRequest*)request;

@end

@implementation BNHTTPDownload

@synthesize request = _request;

+ (id)downloadWithURL:(NSURL*)url progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure {
  return [[BNHTTPDownload alloc] initWithURL:url progress:progress success:success failure:failure];
}

+ (id)downloadWithURL:(NSURL*)url {
  return [self downloadWithURL:url progress:nil success:nil failure:nil];
}

#pragma mark - Garbage collection

- (void)dealloc {
  [self cancel];
}

#pragma mark - Setup

- (id)initWithURL:(NSURL*)url progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure {
  
  self.request = [NSURLRequest requestWithURL:url];
  
  self = [super initWithRequest:self.request];
  if (self) {
    __weak BNHTTPDownload* this = self;
    
    [self setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.outputStreamPath append:NO];
    
    [self setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
      [this didSucceed:responseObject];
      if (success) success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [this didFail:error];
      if (failure) failure(operation, error);
    }];
    
    [self setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
      [this didProgress:bytesRead total:totalBytesRead expected:totalBytesExpectedToRead];
      if (progress) progress(bytesRead, totalBytesRead, totalBytesExpectedToRead);
    }];
  }
  return self;
}

- (void)setRequest:(NSURLRequest*)request {
  _request = request;
}

- (NSString*)outputStreamPath {
  NSString* urlString = self.request.URL.absoluteString;
  
  const char* ptr = [urlString UTF8String];
  unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
  CC_MD5(ptr, strlen(ptr), md5Buffer);
  NSMutableString* hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [hash appendFormat:@"%02x", md5Buffer[i]];
  }

  NSString* extension = self.request.URL.pathExtension;
  NSString* path = [NSString stringWithFormat:@"%@.%@", hash, extension];

  return [NSTemporaryDirectory() stringByAppendingPathComponent:path];
}

- (NSString*)destinationPath {
  NSString* documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  return [documentsDirectory stringByAppendingPathComponent:self.request.URL.absoluteString];
}

#pragma mark - Breakdown

- (void)cancel {
  [super cancel];
  [self didGetCanceled];
}

#pragma mark - Status

- (double)progress {
  if (_totalBytesExpectedToRead > 0) {
    return MIN(1.0f, ((double)_totalBytesRead / (double)_totalBytesExpectedToRead));
  } else {
    return 0.0f;
  }
}

#pragma mark - Operation callbacks

- (void)didProgress:(NSUInteger)bytesRead total:(long long)totalBytesRead expected:(long long)totalBytesExpectedToRead {
  _totalBytesRead = totalBytesRead;
  _totalBytesExpectedToRead = totalBytesExpectedToRead;
  
  [self messageObserversForOperationProgress];
}

- (void)didGetCanceled {
  _totalBytesExpectedToRead = 0;
  _totalBytesRead = 0;
  NSLog(@"Download was canceled (it may have already finished)");
  [self didEnd];
}

- (void)didSucceed:(id)responseObject {
  _totalBytesExpectedToRead = _totalBytesRead;
  NSLog(@"Download completed: %lld bytes", _totalBytesRead);
  
  if ([NSFileManager.defaultManager fileExistsAtPath:self.outputStreamPath]) {
    NSLog(@"Moving file into place...");
    NSError* err;
    [NSFileManager.defaultManager moveItemAtPath:self.outputStreamPath toPath:self.destinationPath error:&err];
  }
  
  [self didEnd];
}

- (void)didFail:(NSError*)error {
  NSLog(@"Download failed: %@", error);
  [self didEnd];
}

- (void)didEnd {
  [self messageObserversForOperationEnd];
}

#pragma mark - Observers
#pragma mark Management

- (BOOL)isBeingObservedBy:(id<BNDownloadObserver>)object {
  return [self.observers containsObject:object];
}

- (void)addObserver:(id<BNDownloadObserver>)observer {
  if (observer && ![self isBeingObservedBy:observer]) {
    NSMutableSet* mObservers = self.observers.mutableCopy;
    [mObservers addObject:observer];
    self.observers = mObservers.copy;
  }
}

- (void)removeObserver:(id<BNDownloadObserver>)observer {
  if (observer) {
    NSMutableSet* mObservers = self.observers.mutableCopy;
    [mObservers removeObject:observer];
    self.observers = mObservers.copy;
  }
}

#pragma mark Messaging

- (void)messageObserversForOperationStart {
  for (id<BNDownloadObserver> observer in self.observers.allObjects) {
    if ([observer respondsToSelector:@selector(observedDownloadDidStart:)]) {
      [observer observedDownloadDidStart:self];
    }
  }
}

- (void)messageObserversForOperationProgress {
  for (id<BNDownloadObserver> observer in self.observers.allObjects) {
    if ([observer respondsToSelector:@selector(observedDownloadDidProgress:)]) {
      [observer observedDownloadDidProgress:self];
    }
  }
}

- (void)messageObserversForOperationEnd {
  for (id<BNDownloadObserver> observer in self.observers.allObjects) {
    if ([observer respondsToSelector:@selector(observedDownloadDidEnd:)]) {
      [observer observedDownloadDidEnd:self];
    }
  }
}

@end
