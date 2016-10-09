//
//  PhotoGalleryCell.m
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/2/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlickrPhoto.h"
#import "PhotoGalleryCell.h"

@implementation PhotoGalleryCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = nil;
    }
    
    // Theoretically this helps with UICollectionView performance
    // http://stackoverflow.com/questions/16336772/uicollectionview-performance-updatevisiblecellsnow
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    return self;
}

@end
