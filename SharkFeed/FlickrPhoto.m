//
//  FlickrPhoto.m
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/3/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlickrPhoto.h"

@interface FlickrPhoto ()

@property (nonatomic, strong) NSString *thumbnailURL;
@property (nonatomic, strong) NSString *mediumURL;
@property (nonatomic, strong) NSString *largeURL;
@property (nonatomic, strong) NSString *originalURL;

@end

@implementation FlickrPhoto

- (id)initWithJSON:(NSDictionary *)jsonBlob
{
    if ( self = [super init] ) {
        _id = [jsonBlob valueForKey:@"id"];
        _owner = [jsonBlob valueForKey:@"owner"];
        _title = [jsonBlob valueForKey:@"title"];
        _descr = [jsonBlob valueForKey:@"description"];
        
        _thumbnailURL = [jsonBlob valueForKey:@"url_t"];
        _mediumURL = [jsonBlob valueForKey:@"url_c"];
        _largeURL = [jsonBlob valueForKey:@"url_l"];
        _originalURL = [jsonBlob valueForKey:@"url_o"];
        _thumbnailImage = NULL;
        _mediumImage = NULL;
        _largeImage = NULL;
        _originalImage = NULL;
    }
    return self;
}

- (UIImage *) getBestThumbnail
{
    if (_mediumImage != NULL) {
        return _mediumImage;
    } else {
        return _thumbnailImage;
    }
}

- (NSString *) getThumbnailURL:(BOOL) mediumImage
{
    if (mediumImage) {
        if (_mediumURL != NULL) {
            return _mediumURL;
        } else if (_originalURL != NULL) {
            return _originalURL;
        } else  {
            return _thumbnailURL;
        }
    } else {
        if (_thumbnailURL != NULL) {
            return _thumbnailURL;
        } else if (_mediumURL != NULL) {
            return _mediumURL;
        } else {
            return _originalURL;
        }
    }
}

- (NSString *) getOriginalURL
{
    if (_originalURL != NULL) {
        return _originalURL;
    } else if (_largeURL != NULL) {
        return _largeURL;
    } else if (_mediumURL != NULL) {
        return _mediumURL;
    } else {
        return _thumbnailURL;
    }
}

- (UIImage *) getBestImage
{
    if (_originalImage != NULL) {
        return _originalImage;
    } else if (_largeImage != NULL) {
        return _largeImage;
    } else if (_mediumImage != NULL) {
        return _mediumImage;
    } else {
        return _thumbnailImage;
    }
}

- (void) setImage:(UIImage *)image size:(FlickrPhotoSize)size
{
    if (size == FLICKR_SIZE_THUMBNAIL) {
        self.thumbnailImage = image;
        
    } else if (size == FLICKR_SIZE_MEDIUM) {
        self.mediumImage = image;
        
    } else if (size == FLICKR_SIZE_LARGE) {
        self.largeImage = image;
        
    } else if (size == FLICKR_SIZE_ORIGINAL) {
        self.originalImage = image;
    }
}

@end
