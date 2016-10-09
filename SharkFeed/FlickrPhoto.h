//
//  FlickrPhoto.h
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/3/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#ifndef FlickrPhoto_h
#define FlickrPhoto_h

typedef NS_ENUM(NSUInteger, FlickrPhotoSize) {
    FLICKR_SIZE_THUMBNAIL,
    FLICKR_SIZE_MEDIUM,
    FLICKR_SIZE_LARGE,
    FLICKR_SIZE_ORIGINAL
};

@interface FlickrPhoto : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, assign) NSInteger photoId; // ordered number sequence that photo was loaded in, e.g. 1, 2, 3
@property (nonatomic, strong) NSString *owner;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *descr;

@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, strong) UIImage *mediumImage;
@property (nonatomic, strong) UIImage *largeImage;
@property (nonatomic, strong) UIImage *originalImage;

- (id)initWithJSON:(NSDictionary *)jsonBlob;
- (UIImage *) getBestThumbnail;
- (UIImage *) getBestImage;
- (NSString *) getThumbnailURL:(BOOL) mediumImage;
- (NSString *) getOriginalURL;
- (void) setImage:(UIImage *)image size:(FlickrPhotoSize)size;

@end

#endif /* FlickrPhoto_h */
