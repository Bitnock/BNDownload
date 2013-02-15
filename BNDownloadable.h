//
//  BNDownloadable.h
//  BNDownload
//
//  Created by Christopher Kalafarski on 1/6/13.
//  Copyright (c) 2012 Bitnock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol BNDownloadable <NSObject>

@property (nonatomic, strong, readonly) NSURL* downloadURL;

@property (nonatomic, readonly) BOOL isDownloaded;
@property (nonatomic, readonly) BOOL isDownloading;

- (void)download:(id)sender;
- (void)undownload:(id)sender;

@end
