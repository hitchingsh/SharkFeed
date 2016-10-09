//
//  FlickrPhotoMgr.m
//  SharkFeed
//  Encapsulates Flicker API and acts as a look ahead cache for fetching photos
//
//  Created by Hamilton Hitchings on 10/4/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlickrPhoto.h"
#import "FlickrPhotoMgr.h"

// Used for infinite scroll when you stop receiving results and loop back to beginning
static NSInteger const infiniteLoopSize = 100000;

@interface FlickrPhotoMgr ()

@property (atomic, strong) NSArray *photos;

@property (nonatomic, strong) NSString *searchTerm;
@property (nonatomic, assign) NSInteger initialQualityPhotos;
@property (nonatomic, assign) NSInteger photosPerPage;
@property (nonatomic, assign) NSInteger currentPageNum;
@property (nonatomic, assign) NSInteger photosRequested;
@property (nonatomic, assign) NSInteger photosFetchedMetaData;
@property (nonatomic, assign) NSInteger thumbnailImagesLoaded;
@property (atomic, strong) NSOperationQueue *fetchPhotosQueue;
@property (nonatomic, assign) BOOL prefetching;

@property (copy) void (^completionHandler)(void);
@property (copy) void (^reloadCompletionHandler)(void);

@end

@implementation FlickrPhotoMgr

- (id)init:(NSString *)searchTerm photosFirstPage:(NSInteger)initialQualityPhotos photosPerPage:(NSInteger)photosPerPage
{
    if ( self = [super init] ) {
        _initialQualityPhotos = initialQualityPhotos;
        _photosPerPage = photosPerPage;
        _searchTerm = [searchTerm stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        _completionHandler = NULL;

        [self reset];
        
        _fetchPhotosQueue = [[NSOperationQueue alloc] init];
        [_fetchPhotosQueue setMaxConcurrentOperationCount:1];

        // Fetch initial photos
        [self fetchPhotos];
    }
    return self;
}

// Called after load new photos (e.g. to reload UICollectionView)
- (void) setPhotosLoadedCompletionHandler:(void (^)(void))completionHandler
{
    _completionHandler = completionHandler;
}

- (void) reset
{
    _photos = [[NSMutableArray alloc] init];
    _currentPageNum = 0;
    _photosRequested = 0;
    _totalPhotos = 0;
    _photosFetchedMetaData = 0;
    _thumbnailImagesLoaded = 0;
    _prefetching = NO;
    _reloadCompletionHandler = NULL;
}

// Reload photos
- (void) reload:(void (^)(void))reloadCompletionHandler
{
    if (!_prefetching) {
        [self reset];
        _completionHandler();
        _reloadCompletionHandler = reloadCompletionHandler;
        [self fetchPhotos];
    } else {
        reloadCompletionHandler();
    }
}

- (FlickrPhoto *) getPhoto:(NSInteger) index
{
    // Handles looping when no longer getting new photos
    if (index >= _photos.count) {
        index = index % _photos.count;
    }
    if (index >= _photos.count)
        NSLog(@"ERROR");
    
    return _photos[index];
}

- (void) prefetchPhotos:(NSInteger)index
{
    @synchronized (self) { // Synchronize to avoid race condition but since on main thread probably not necessary
        
        // Fetch more photos when getting close to end of list.  Once start looping, don't fetch
        if (index >= _photosRequested - _photosPerPage && _totalPhotos != infiniteLoopSize && !_prefetching) {
        
            _prefetching = YES; // This gets set to NO once all photos requested have been fetched.

            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                            initWithTarget:self
                                                            selector:@selector(fetchPhotos)
                                                            object:nil];
        
            [_fetchPhotosQueue addOperation:operation];
        }
    }
}

- (void) fetchPhotos
{
    NSInteger photosPerPage = _photosPerPage;
    BOOL initialPhotos = NO;
    if (_photosFetchedMetaData < _initialQualityPhotos) {
        initialPhotos = YES;
        photosPerPage = _initialQualityPhotos;
    }
    
    _photosRequested += photosPerPage;

    NSString *flickrAPIKey = @"949e98778755d1982f537d56236bbb42";
    NSString *urlString = [[NSString alloc] initWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&text=%@&format=json&nojsoncallback=1&page=%ld&per_page=%ld&extras=url_t,url_c,url_l,url_o,description", flickrAPIKey, _searchTerm, ++_currentPageNum, photosPerPage];
    
    NSLog(@"fetchPhotos for pageNum=%ld for urlString=%@", _currentPageNum, urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Call Flickr API to get photo search results meta data
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSError *e = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&e];
            
            NSDictionary *photos = [json valueForKey:@"photos"];
            
            if (_currentPageNum == 1) { // Since already incremented _currentPageNum
                NSNumber *totalNum = [photos objectForKey:@"total"];
                NSLog(@"total photos matching search criteria=%@", totalNum);
            }
            
            NSArray *photo = [photos valueForKey:@"photo"];

            if (photo.count > 0) {
                
                NSMutableArray *newPhotos = [[NSMutableArray alloc] init];
                
                // Populate FlickrPhoto objects with json properties
                for (NSDictionary *jsonPhoto in photo) {
                    FlickrPhoto *photo = [[FlickrPhoto alloc] initWithJSON:jsonPhoto];
                    
                    photo.photoId = ++_photosFetchedMetaData; // Use of loading initial visible photos
                    
                    [newPhotos addObject:photo];
                }
                
                [self fetchPhotoImages:initialPhotos newPhotos:[NSArray arrayWithArray:newPhotos]];
                
                // PRODUCTION CODE TODO: remove images from least recently used photos after get to several thousand to avoid memory bloat

            } else {
                NSLog(@"fetched 0 photos, so end of search results, now start looping");
                _totalPhotos = infiniteLoopSize;
                _photosRequested -= photosPerPage;

                _completionHandler();
                _prefetching = NO;
            }
        } else {
            NSLog(@"Error fetching URL from Flickr %@", error);
            _photosRequested -= photosPerPage;
            _prefetching = NO;
        }
    }];
    
    [downloadTask resume];
}

- (void) fetchPhotoImages:(BOOL)initialPhotos newPhotos:(NSArray *)newPhotos
{
    NSInteger finalPhoto = _thumbnailImagesLoaded + newPhotos.count;
    
    NSInteger thumbnailsRequested = _thumbnailImagesLoaded;
    
    for (FlickrPhoto *photo in newPhotos) {
        
        [self fetchThumbnail:photo mediumImage:(thumbnailsRequested++ < _initialQualityPhotos) completionHandler:^(UIImage *image, FlickrPhoto* photo) {
            
            _thumbnailImagesLoaded++;
            
            if (_thumbnailImagesLoaded == finalPhoto) {
                
                _photos = [_photos arrayByAddingObjectsFromArray:newPhotos];
                
                if (_totalPhotos < _photos.count && _totalPhotos < infiniteLoopSize) {
                    _totalPhotos = _photos.count;
                }
                
                NSLog(@"RELOAD FlickrPhotoMgr calling completionHandler _thumbnailImagesLoaded=%ld total photos=%ld", _thumbnailImagesLoaded, _totalPhotos);
                // Reloads UICollectionView once new images fetched
                if (_completionHandler) {
                    _completionHandler();
                }
                
                // Called when reload UICollectionView with new images, e.g. on pull to refresh
                if (_reloadCompletionHandler) {
                    _reloadCompletionHandler();
                    _reloadCompletionHandler = NULL; // Remove after reload so only called once
                }
                
                _prefetching = NO;
                
                if (_thumbnailImagesLoaded == _initialQualityPhotos) {
                    // Fetch next batch of thumbnails for initial smooth scrolling
                    
                    [self prefetchPhotos:_thumbnailImagesLoaded - 1];
                }
            }
        }];
    }
}

- (void) fetchThumbnail:(FlickrPhoto *)photo mediumImage:(BOOL)mediumImage completionHandler:(void (^)(UIImage *image, FlickrPhoto *photo))completionHandler;
{
    NSString *url = [photo getThumbnailURL:mediumImage];
    
    FlickrPhotoSize size = FLICKR_SIZE_THUMBNAIL;
    if (mediumImage)
        size = FLICKR_SIZE_MEDIUM;
    
    [self fetchPhotoInternal:photo url:url size:size completionHandler:completionHandler];
}

- (void) fetchFullPhoto:(FlickrPhoto *)photo completionHandler:(void (^)(UIImage *image, FlickrPhoto *photo))completionHandler;
{
    [self fetchPhotoInternal:photo url:[photo getOriginalURL] size:FLICKR_SIZE_ORIGINAL completionHandler:completionHandler];
}

- (void) fetchPhotoInternal:(FlickrPhoto *)photo url:(NSString *)url size:(FlickrPhotoSize)size completionHandler:(void (^)(UIImage *image, FlickrPhoto *photo))completionHandler;
{
    NSURLSessionDownloadTask *task =
    [[NSURLSession sharedSession]
     downloadTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
         UIImage *downloadedImage = [UIImage imageWithData: [NSData dataWithContentsOfURL:location]];
         
         if (error != nil) {
             NSLog(@"Error fetching URL=%@", error);
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             [photo setImage:downloadedImage size:size];
             
             if (completionHandler != NULL) {
                 completionHandler(downloadedImage, photo);
             }
         });
     }];
    
    // self.task = task;
    [task resume];
}

@end
