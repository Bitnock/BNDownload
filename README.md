## BNDownload

BNDownload depends on AFNetworking

#### How to use

(Examples assume you have an `ABEpisode` class that you will be downloading)

##### BNDownloadManager

* [NSOperationQueue Class Reference](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/NSOperationQueue_class/Reference/Reference.html)

`BNDownloadManager` is subclass of `NSOperationQueue`. It does not do a whole lot, and is intended to be subclassed simply so it's a little easier to keep track of the specific things in your app that you are downloading. You should have one download manager for each class of thing you are downloading.

**Ex.** The `ABEpisodeDownloadManager` sublass should look something like

	+ (ABEpisodeDownloadManager*)sharedManager {
	  @synchronized(self) {
	    if (sharedManager == nil) {
	      sharedManager = self.new;
	    }
	  }
	  
	  return sharedManager;
	}
	
	- (void)addOperation:(ABEpisodeDownload*)download {
	  if (![self downloadInQueueWithEpisode:download.episode]) {
	    [super addOperation:download];
	  }
	}
	
	- (ABEpisodeDownload*)downloadInQueueWithEpisode:(ABEpisode<BNDownloadable>*)episode {
	  for (ABEpisodeDownload* download in self.operations) {
	    if ([download.request.URL isEqual:episode.downloadURL]) {
	      return download;
	    }
	  }
	  
	  return nil;
	}
	
The `addOperation:` method could be a good place to do any sort of analytics on downloads. Also note that an `ABEpisodeDownload` is being added to the queue, not an `ABEpisode` itself. This is to remain consistent with `NSOperationQueue`.

BNDownloadManager provides no means of persisting the operation queue between app launches. This is something you should add in your subclass; it's recommended that what you persist should reflect the original object you are downloading, not just the URL that eventually gets added to the NSOperationQueue.

##### BNDownload

* [AFHTTPRequestOperation Class Reference](http://engineering.gowalla.com/AFNetworking/Classes/AFHTTPRequestOperation.html)
* [AFURLConnectionOperation Class Reference](http://engineering.gowalla.com/AFNetworking/Classes/AFURLConnectionOperation.html)
* [NSOperation Class Reference](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html)

`BNHTTPDownload` is a subclass of `AFHTTPRequestOperation`. It it intended to be subclassed, so that you can keep track of the object that you are downloading in a meaningful way. It also provides an observer pattern to make common cases of monitoring a download simpler.

Your `BNHTTPDownload` subclass is what you will eventually hand to your DownloadManager, so it's main purpose is simply to create the download object, not to actual initiate the download itself.

There are several private methods that you can use to handle common operation events:

	- (void)didProgress:(NSUInteger)bytesRead total:(long long)totalBytesRead expected:(long long)totalBytesExpectedToRead;
	- (void)didGetCanceled;
	- (void)didSucceed:(id)responseObject;
	- (void)didFail:(NSError*)error;
	- (void)didEnd;
	
Additionally, when you create each download, you can pass in blocks that will get called on progress, success, and failure just for that download.

###### Destination path

`BNHTTPDownload` sets a destination path for the downloaded file of 
	
	[Documents Directory]/[URL of request]
	
You will likely want to override that.

**Ex.** The ABEpisodeDownload could look something like

	@interface ABEpisodeDownload : BNHTTPDownload
	
	+ (id)downloadWithEpisode:(ABEpisode<BNDownloadable>*)episode progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;
	+ (id)downloadWithEpisode:(ABEpisode<BNDownloadable>*)episode;
	
	@property (nonatomic, strong, readonly) ABEpisode<BNDownloadable>* episode;
	
	- (id)initWithEpisode:(ABEpisode<BNDownloadable>*)episode progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;
	
	@end
	
	/////// /////// /////// /////// /////// /////// /////// ///////

	@interface ABEpisodeDownload ()
	
	- (void)setEpisode:(ABEpisode<BNDownloadable>*)episode;
	
	@end
	
	@implementation ABEpisodeDownload
	
	+ (id)downloadWithEpisode:(ABEpisode<BNDownloadable>*)episode progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
	  return [[ABEpisodeDownload alloc] initWithEpisode:episode progress:progress success:success failure:failure];
	}
	
	+ (id)downloadWithEpisode:(ABEpisode<BNDownloadable>*)episode {
	  return [self downloadWithEpisode:episode progress:nil success:nil failure:nil];
	}
	
	- (id)initWithEpisode:(ABEpisode<BNDownloadable>*)episode progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure {
	  self = [super initWithURL:episode.downloadURL progress:progress success:success failure:failure];
	  if (self) {
	    self.episode = episode;
	  }
	  return self;
	}
	
	- (void)setEpisode:(ABEpisode<BNDownloadable>*)episode {
	  _episode = episode;
	}
	
	- (NSString*)destinationPath {
	  NSString* urlString = self.request.URL.absoluteString;
	  
	  const char* ptr = [urlString UTF8String];
	  unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
	  CC_MD5(ptr, strlen(ptr), md5Buffer);
	  NSMutableString* hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
	    [hash appendFormat:@"%02x", md5Buffer[i]];
	  }
	  
	  NSString* extension = self.request.URL.pathExtension;
	  NSString* filename = [NSString stringWithFormat:@"%@.%@", hash, extension];
	  
	  NSString* documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	  NSString* downloadDirectory = [documentsDirectory stringByAppendingPathComponent:@"EpisodeDownloads"];
	  
	  return [downloadDirectory stringByAppendingPathComponent:filename];
	}
	
	- (void)didSucceed:(id)responseObject {
	  self.episode.localFileURL = [NSURL fileURLWithPath:self.destinationPath];
	  
	  [super didSucceed:responseObject];
	  
	  if ([ABAudioPlayer.sharedPlayer.currentEpisode isEqualToEpisode:self.episode]
	      && ABAudioPlayer.sharedPlayer.player.rate > 0) {
	    // Restart playback to switch to local file
	    [ABAudioPlayer.sharedPlayer pause];
	    [ABAudioPlayer.sharedPlayer playEpisode:self.episode];
	  }
	  
	  [self didEnd];
	}
	
	@end
	
##### BNDownloadable

The model you are downloading with your Manager and Download should implement the `BNDownloadable` protocol.

The only interesting part here really is the `isDownloading` method. You just want to make sure you can reliable know the state of the download in the `NSOperationQueue`.

In download: whether you allow an object to be downloaded multiple times is up to you.

The sender on download: and undownload: is an object you want to become an observer when the Downloadable gets downloaded.

**Ex.** ABEpisode may look like

	- (NSURL*)downloadURL {
	  return self.h264videoURL;
	}
	
	- (BOOL)isDownloaded {
	  return !!self.file.localFileURI;
	}
	
	- (BOOL)isDownloading {
	  ABEpisodeDownload* download = [ABEpisodeDownloadManager.sharedManager downloadInQueueWithEpisode:self];
	  
	  if (download && !download.isCancelled) {
	    return (download.isExecuting || download.isReady);
	  }
	
	  return NO;
	}
	
	- (void)download:(id)sender {
	  if (!self.isDownloaded) {
	    ABEpisodeDownload* download = [ABEpisodeDownload downloadWithEpisode:self];
	    [download addObserver:sender];
	    [ABEpisodeDownloadManager.sharedManager addOperation:download];
	  }
	}
	
	- (void)undownload:(id)sender {
	  if (self.isDownloaded) {
	    ABEpisodeDownload* download = [ABEpisodeDownload downloadWithEpisode:self];
	    [NSFileManager.defaultManager removeItemAtPath:download.destinationPath error:nil];
        [download removeObserver:sender];
	    self.file.localFileURL = nil;
	    
	    if ([ABAudioPlayer.sharedPlayer.currentEpisode isEqualToEpisode:self] && ABAudioPlayer.sharedPlayer.player.rate > 0.0f) {
	      // Switch back to streaming file
	      [KRTAudioPlayer.sharedPlayer pause];
	      [KRTAudioPlayer.sharedPlayer playEpisode:self];
	    }
	  } else if (self.isDownloading) {
	    ABEpisodeDownload* download = [ABEpisodeDownloadManager.sharedManager downloadInQueueWithEpisode:self];
	    [download removeObserver:sender];
	    [download cancel];
	  }
	}

##### BNDownloadObserver

When you want to observe a download, and you're using the built in observer pattern, the object doing the observing should implement the `BNDownloadObserver` protocol.

**Ex.** A table cell that is observing a particular download

	@interface ABEpisodeTableViewCell : UITableViewCell <BNDownloadObserver>

	@end
	
	@implementation ABEpisodeTableViewCell
	
	- (void)registerAsObserverForDownload:(BNHTTPDownload*)download {
	    [download addObserver:self];
	  }
	
	- (void)unregisterAsObserverForDownload:(BNHTTPDownload*)download {
	  [download removeObserver:self];
	}
	
	- (IBAction)observedDownloadDidStart:(BNHTTPDownload*)sender {
	  
	}
	
	- (IBAction)observedDownloadDidProgress:(BNHTTPDownload*)sender {
	  [self updateCellForDownloadProgress];
	}
	
	- (IBAction)observedDownloadDidEnd:(BNHTTPDownload*)sender {
	  [self styleCellForDownload];
	  [self unregisterAsObserverForDownload:sender];
	}
	
	@end
	
You should sure to unregister observers as necessary. If this is overly combersome it may be worth skipping the built in observer functionality and simply using KVO or notifications.

**Ex.**	For a table cell

	- (void)dealloc {
	  if ([ABEpisodeDownloadManager.sharedManager downloadInQueueWithEpisode:self.episode]) {
	    ABEpisodeDownload* download = [ABEpisodeDownloadManager.sharedManager downloadInQueueWithEpisode:self.episode];
	    [self unregisterAsObserverForDownload:download];
	  }
	}
	
	- (void)prepareForReuse {
	  [super prepareForReuse];
	  
	  if ([ABEpisodeDownloadManager.sharedManager downloadInQueueWithEpisode:self.episode]) {
	    ABEpisodeDownload* download = [ABEpisodeDownloadManager.sharedManager downloadInQueueWithEpisode:self.episode];
	    [self unregisterAsObserverForDownload:download];
	  }
    }
    
You may also want to consider wrapping this up in your Manager if you do it a lot.

	
#### Implementation

**Ex.** A common use case may end up looking like

	- (void)downloadControlAction:(id)sender {
	  if (self.episode.isDownloaded) {
	    [self.episode undownload:self];
	  } else if (self.episode.isDownloading) {
	    [self.episode undownload:self];
	  } else {
	    [self.episode download:self];
	  }
	}
	
## Multiple downloads

If you have an app that downloads many type of items and you therefore have many download and manager subclasses, but need to monitor them in aggregate, you should write a abstraction layer that observes the operation queue for your various managers, and responds as needed. Such functionality is outside the scope of this library.

It may be worth creating a primary subclass of BNDownloadManager if there are things that all your downloads share, such as an analytics hook when downloads move through their lifecycle.