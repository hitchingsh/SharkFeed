//
//  ViewController.m
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/2/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlickrPhoto.h"
#import "FlickrPhotoMgr.h"
#import "PhotoGallery.h"
#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _photoMgr = [[FlickrPhotoMgr alloc] init:@"shark" photosFirstPage:25 photosPerPage:100];
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Allow swiping in either direction to proceed to Shark Gallery (more user friendly)
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];

    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;

    [self.view addGestureRecognizer:swipeRight];
    [self.view addGestureRecognizer:swipeLeft];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture
{
    [self performSegueWithIdentifier:@"ShowPhotoGallery" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowPhotoGallery"])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIKeyboardDidShowNotification
                                                      object:nil];
        PhotoGallery *pg = (PhotoGallery *)segue.destinationViewController;
        pg.photoMgr = _photoMgr;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
