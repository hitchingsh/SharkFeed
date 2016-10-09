//
//  PhotoGallery.m
//  SharkFeed
//
//  Created by Hamilton Hitchings on 10/2/16.
//  Copyright © 2016 Imagical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlickrPhoto.h"
#import "FlickrPhotoMgr.h"
#import "PhotoGalleryCell.h"
#import "PhotoGallery.h"
#import "Lightbox.h"

@interface PhotoGallery ()

@property (nonatomic, strong) FlickrPhoto *photoSelected;

@end

@implementation PhotoGallery

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Call reloadData in case initial visible images have finished loading that started in ViewController
    [self.collectionView reloadData];
    
    // Required to use weak reference of self in block
    __unsafe_unretained typeof(self) weakSelf = self;
    
    [_photoMgr setPhotosLoadedCompletionHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.collectionView reloadData];
        });
    }];
    
    [self setupPullToRefresh];
}

- (void) setupPullToRefresh
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor clearColor];
    refreshControl.backgroundColor = [UIColor clearColor];
    
    [refreshControl addTarget:self action:@selector(startRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    self.collectionView.alwaysBounceVertical = YES;
    UIImageView *hookView = [[UIImageView alloc] init];
    UIImageView *fishView = [[UIImageView alloc] init];
    UILabel *pullText = [[UILabel alloc] init];
    
    hookView.image = [UIImage imageNamed:@"PullHook"];
    hookView.frame = CGRectMake(0, 0, 22, 33);
    
    fishView.image = [UIImage imageNamed:@"PullFish"];
    fishView.frame = CGRectMake(0, 34, 28, 44);
    
    pullText.text = NSLocalizedString(@"Pull to refresh sharks", nil);
    pullText.frame = CGRectMake(0, 78, 200, 44);
    
    [hookView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [fishView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [pullText setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [refreshControl addSubview:hookView];
    [refreshControl addSubview:fishView];
    [refreshControl addSubview:pullText];
    
    [refreshControl addConstraints:({
        @[
          [NSLayoutConstraint
           constraintWithItem:hookView
           attribute:NSLayoutAttributeCenterX
           relatedBy:NSLayoutRelationEqual
           toItem:refreshControl
           attribute:NSLayoutAttributeCenterX
           multiplier:1.f constant:0.f],
          
          [NSLayoutConstraint
           constraintWithItem:fishView
           attribute:NSLayoutAttributeTop
           relatedBy:NSLayoutRelationEqual
           toItem:hookView
           attribute:NSLayoutAttributeBottom
           multiplier:1.f constant:5.f],
          
          [NSLayoutConstraint
           constraintWithItem:fishView
           attribute:NSLayoutAttributeCenterX
           relatedBy:NSLayoutRelationEqual
           toItem:refreshControl
           attribute:NSLayoutAttributeCenterX
           multiplier:1.f constant:-0.f],
          
          [NSLayoutConstraint
           constraintWithItem:fishView
           attribute:NSLayoutAttributeBottom
           relatedBy:NSLayoutRelationEqual
           toItem:pullText
           attribute:NSLayoutAttributeTop
           multiplier:1.f constant:-25.f],
          
          [NSLayoutConstraint
           constraintWithItem:pullText
           attribute:NSLayoutAttributeCenterX
           relatedBy:NSLayoutRelationEqual
           toItem:refreshControl
           attribute:NSLayoutAttributeCenterX
           multiplier:1.f constant:0.f],
          
          [NSLayoutConstraint
           constraintWithItem:pullText
           attribute:NSLayoutAttributeBottom
           relatedBy:NSLayoutRelationEqual
           toItem:refreshControl
           attribute:NSLayoutAttributeBottomMargin
           multiplier:1.f constant:-10.f]
          ];
    })];
}

- (void) startRefresh:(UIRefreshControl *) refreshControl
{
    [_photoMgr reload:^{
        if (refreshControl.isRefreshing) {
            [refreshControl endRefreshing];
        }
        NSLog(@"Finished reload");
    }];
}

- (void) fetchQualityThumbnail:(PhotoGalleryCell *)cell
{
    if (cell.photo.mediumImage != NULL) {
        cell.imageView.image = cell.photo.mediumImage;
    } else {
        [_photoMgr fetchThumbnail:cell.photo mediumImage:YES completionHandler:^(UIImage *image, FlickrPhoto *photo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (photo.id == cell.photo.id) {
                    cell.imageView.image = image;
                } else {
                    // NSLog(@"Cell now has older photo id than loaded so ignoring it");
                }
            });
        }];
    }
}

- (void) fetchQualityThumbnails
{
        NSArray *visibleCells = self.collectionView.visibleCells;
        for (PhotoGalleryCell *cell in visibleCells) {
            [self fetchQualityThumbnail:cell];
        }
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;

    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];

        reusableview = headerView;
        
        UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *) [self.collectionView collectionViewLayout];
        flow.sectionHeadersPinToVisibleBounds = YES;
    }
    
    if (kind == UICollectionElementKindSectionFooter) {

        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
        
        for (UIView *view in footerView.subviews) {
            if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
                // Make the Activity View Indicator a bit bigger since default size is too small
                CGAffineTransform transform = CGAffineTransformMakeScale(1.5f, 1.5f);
                view.transform = transform;
            }
        }
        
        reusableview = footerView;
    }
    
    return reusableview;
}

- (NSInteger) collectionView:(UICollectionView *) collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return _photoMgr.totalPhotos;
}

-(UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
     PhotoGalleryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    FlickrPhoto *photo = [_photoMgr getPhoto:indexPath.item];
    
    if (photo == NULL) {
        NSLog(@"ERROR photo is NULL in cellForItemAtIndexPath for index=%ld", indexPath.item);
    }
    
    if (![photo.id isEqualToString:cell.photo.id]) {
        
        cell.photo = photo;
        cell.imageView.image = [photo getBestThumbnail];
    }
    
    [_photoMgr prefetchPhotos:indexPath.item];

    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _photoSelected = [_photoMgr getPhoto:indexPath.item];
    [self performSegueWithIdentifier:@"ShowLightbox" sender:self];
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Stopped scrolling
    [self fetchQualityThumbnails];
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    // Stopped scrolling
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self fetchQualityThumbnails];
}

// The 320 implementations are so much better - here is a patch to get consistent start/ends of the scroll.
-(void)scrollViewDidScroll:(UIScrollView *)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    //ensure that the end of scroll is fired.
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.0];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // Moving
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    // Moving
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat itemsPerRow = 3.0;
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        itemsPerRow = 5.0;
    }
    
    UIEdgeInsets sectionInsets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);

    CGFloat paddingSpace = sectionInsets.left * (itemsPerRow + 1);
    CGFloat availableWidth = collectionView.frame.size.width - paddingSpace - 1;
    CGFloat widthPerItem = roundf(availableWidth / itemsPerRow);
    
    return CGSizeMake(widthPerItem, widthPerItem);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    //reload the collectionview layout after rotating
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    [layout invalidateLayout];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowLightbox"])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIKeyboardDidShowNotification
                                                      object:nil];
        Lightbox *vc = (Lightbox *)segue.destinationViewController;
        vc.photo = _photoSelected;
        vc.photoMgr = _photoMgr;
    }
}

@end
