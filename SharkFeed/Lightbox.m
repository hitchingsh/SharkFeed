//
//  Lightbox.m
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/5/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlickrPhoto.h"
#import "FlickrPhotoMgr.h"
#import "Lightbox.h"

@interface Lightbox ()

@end

@implementation Lightbox

- (void) viewDidLoad
{
    _imageView.image = [_photo getBestImage];
    
    [_photoMgr fetchFullPhoto:_photo completionHandler:^(UIImage *image, FlickrPhoto *photo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image != NULL) {
                _imageView.image = image;
            } else {
                NSLog(@"ERROR: Lightbox could not fetch full sized image");
            }
        });
    }];
}

- (IBAction)closeCallback:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)downloadCallback:(id)sender {
    UIImageWriteToSavedPhotosAlbum(_photo.originalImage, nil, nil, nil);
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Success!", nil)
                                 message:NSLocalizedString(@"Photo downloaded to camera roll", nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Ok", nil)
                                style:UIAlertActionStyleDefault
                                handler:nil];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)openFlickr:(id)sender {
    
    NSString *customURL = [[NSString alloc] initWithFormat:@"flickr://photos/%s/%s",
                           [_photo.owner UTF8String], [_photo.id UTF8String]];

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:customURL]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:customURL]];
    } else {
        // Note, opens US app store Flickr app
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/flickr/id328407587?mt=8"]];
    }
}

- (IBAction)downloadCallbackText:(id)sender {
    [self downloadCallback:sender];
}

- (IBAction)openFlickrText:(id)sender {
    [self openFlickr:sender];
}

@end
