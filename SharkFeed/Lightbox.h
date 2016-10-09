//
//  Lightbox.h
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/5/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#ifndef Lightbox_h
#define Lightbox_h

@interface Lightbox : UIViewController

@property (nonatomic, strong) FlickrPhoto *photo;
@property (nonatomic, strong) FlickrPhotoMgr *photoMgr;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)closeCallback:(id)sender;
- (IBAction)downloadCallback:(id)sender;
- (IBAction)downloadCallbackText:(id)sender;
- (IBAction)openFlickr:(id)sender;
- (IBAction)openFlickrText:(id)sender;

@end

#endif /* Lightbox_h */
