//
//  ViewController.m
//  VOMetroLayoutDemo
//
//  Created by ValoLee on 15/1/13.
//  Copyright (c) 2015年 ValoLee. All rights reserved.
//

#import "ViewController.h"
#import "VOMetroLayout.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet VOMetroLayout *metroLayout;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    self.metroLayout.styleArray = @[@[@(1),@(0),@(0),@(0),@(2),@(3),@(0),@(2),@(3)],
                                    @[@(2),@(2),@(2),@(2),@(2),@(2),@(3)],
                                    @[@(1),@(0),@(0),@(0),@(0),@(2),@(3)]];
    return self.metroLayout.styleArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSArray *sectionArray = self.metroLayout.styleArray[section];
    return sectionArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"testCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor blueColor];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"Major: (%@, %@)", @(indexPath.section), @(indexPath.row));
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    NSString *reusedIdentifier = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        reusedIdentifier = @"header";
    }
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        reusedIdentifier = @"footer";
    }
    if (reusedIdentifier) {
        UICollectionReusableView *resuableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reusedIdentifier forIndexPath:indexPath];
        return resuableView;
    }
    return nil;
}


@end
