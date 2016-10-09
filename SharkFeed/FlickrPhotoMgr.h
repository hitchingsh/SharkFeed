//
//  FlickrPhotoMgr.h
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/4/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#ifndef FlickrPhotoMgr_h
#define FlickrPhotoMgr_h

@interface FlickrPhotoMgr : NSObject

@property (nonatomic, assign) NSInteger totalPhotos;

- (id)init:(NSString *)searchTerm photosFirstPage:(NSInteger)photosFirstPage photosPerPage:(NSInteger)photosPerPage;
- (void) setPhotosLoadedCompletionHandler:(void (^)(void))completionHandler; // used to reload photos after add new ones
- (void) reload:(void (^)(void))reloadCompletionHandler; // Used when reload photos (e.g. pull to refresh)
- (FlickrPhoto *) getPhoto:(NSInteger) index;
- (void) prefetchPhotos:(NSInteger)index;
- (void) fetchFullPhoto:(FlickrPhoto *)photo completionHandler:(void (^)(UIImage *image, FlickrPhoto *photo))completionHandler;
- (void) fetchThumbnail:(FlickrPhoto *)photo mediumImage:(BOOL)mediumImage completionHandler:(void (^)(UIImage *image, FlickrPhoto *photo))completionHandler;

@end

#endif /* FlickrPhotoMgr_h */
