//
//  PhotoGalleryCell.h
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/2/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#ifndef PhotoGalleryCell_h
#define PhotoGalleryCell_h

@interface PhotoGalleryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) FlickrPhoto *photo;

@end

#endif /* PhotoGalleryCell_h */
