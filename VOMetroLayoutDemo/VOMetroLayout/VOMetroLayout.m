//
//  VOMetroLayout.m
//  VOMetroLayoutDemo
//
//  Created by ValoLee on 15/1/13.
//  Copyright (c) 2015年 ValoLee. All rights reserved.
//

#import "VOMetroLayout.h"

/**
 *  用来存储cell的属性
 */
@interface VOMetroAttributes : NSObject

@property (nonatomic, assign) CGRect     frame;         // cell在UICollectionView中的frame
@property (nonatomic, assign) NSUInteger area;
@property (nonatomic, assign) NSUInteger posUnits;      // 使用unit数量当前cell的位置(暂未使用,预留给移动Cell准备)
@property (nonatomic, assign) NSUInteger sizeUnits;     // 使用unit数量表示cell的大小

@end

@implementation VOMetroAttributes

@end

@interface VOMetroLayout ()
@property (nonatomic, assign) NSInteger unitsPerArea;    // 按unit计算,每个Area可容纳多少unit,必须为8的倍数
@property (nonatomic, strong) NSArray   *cellAttrsArray;
@property (nonatomic, strong) NSArray   *headerFrameArray;
@property (nonatomic, strong) NSArray   *footerFrameArray;
@property (nonatomic, assign) CGSize    areaSize;

@end

@implementation VOMetroLayout

- (void)prepareLayout{
    [super prepareLayout];
    //TODO,暂只支持横向
    self.areaSize         = [self calcAreaSize];
    if (self.unitsPerSide == 0) {
        self.unitsPerSide = 10;
    }
    CGFloat length        = (self.areaSize.height + self.minimumLineSpacing) / self.unitsPerSide - self.minimumLineSpacing;
    self.itemSize         = CGSizeMake(length, length);
    self.unitsPerArea     = self.unitsPerSide * 4;
    if (self.areaSpacing <= 0) {
        self.areaSpacing  = self.minimumInteritemSpacing * 2;
    }
    [self generateMetroAttrsArrays];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds{
    CGRect newBounds = self.collectionView.bounds;
    if (!CGSizeEqualToSize(oldBounds.size, newBounds.size)) {
        return YES;
    }
    return NO;
}

- (void)setStyleArray:(NSArray *)styleArray{
    if (![_styleArray isEqual:styleArray]) {
        _styleArray = styleArray;
        [self invalidateLayout];
    }
}

#pragma mark 计算area size
- (CGSize)calcAreaSize{
    CGSize size = CGSizeZero;
    size.height = self.collectionView.frame.size.height;
    size.height -= self.sectionInset.top + self.sectionInset.bottom;
    if (self.headerFooterPostion == VOMetroHeaderFooterPositionVertical) {
        size.height -= self.headerReferenceSize.height;
        size.height -= self.footerReferenceSize.height;
    }
    size.width  = self.itemSize.width * 4 + self.minimumInteritemSpacing * 3;
    return size;
}

#pragma mark 计算ContentSize
- (CGSize)collectionViewContentSize{
    CGSize size = CGSizeZero;
    //TODO,暂只支持横向
    size.height = self.collectionView.bounds.size.height;
    size.height += self.collectionView.contentInset.top + self.collectionView.contentInset.bottom;
    for (NSUInteger i = 0 ; i < self.cellAttrsArray.count; i ++) {
        NSArray *sectionAttrs = self.cellAttrsArray[i];
        VOMetroAttributes *attrs = sectionAttrs.lastObject;
        NSUInteger areaCount = attrs.area + 1;
        size.width += areaCount * self.areaSize.width + (areaCount - 1) * self.areaSpacing;
        size.width += self.sectionInset.left + self.sectionInset.right;
        if (self.headerFooterPostion == VOMetroHeaderFooterPositionHorizontal) {
            size.width += self.headerReferenceSize.width;
            size.width += self.footerReferenceSize.width;
        }
    }
    size.width += self.collectionView.contentInset.left + self.collectionView.contentInset.right;
    return size;
}

#pragma mark 每个Item的attributes
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path{
    UICollectionViewLayoutAttributes* attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    NSArray *sectionAttrs = self.cellAttrsArray[path.section];
    VOMetroAttributes *attrs = sectionAttrs[path.row];
    attributes.frame = attrs.frame;
    return attributes;
}

#pragma mark 可视Rect的attributesArray
-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect{
    NSMutableArray* attributesArray = [NSMutableArray array];
    NSArray *visibleIndexPaths = [self indexPathsOfItemsInRect:rect];
    // cell attributes
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }
    
    // header attributes
    NSArray *headerIndexPaths = [self indexPathsOfHeadersInRect:rect];
    for (NSIndexPath *indexPath in headerIndexPaths) {
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }
    
    // header attributes
    NSArray *footerIndexPaths = [self indexPathsOfFootersInRect:rect];
    for (NSIndexPath *indexPath in footerIndexPaths) {
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }
    
    return attributesArray;
}

#pragma mark header和footer的attributes
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        attributes.frame = [self.headerFrameArray[indexPath.section] CGRectValue];
    }
    else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        attributes.frame = [self.footerFrameArray[indexPath.section] CGRectValue];
    }
    return attributes;
}

#pragma mark 根据style数组生成cell,header,footer属性数组
- (void)generateMetroAttrsArrays{
    NSMutableArray *cellAttrsArray   = [NSMutableArray array];
    NSMutableArray *headerFrameArray = [NSMutableArray array];
    NSMutableArray *footerFrameArray = [NSMutableArray array];
    CGPoint areaPos  = CGPointZero;
    CGRect headerFrame, footerFrame;
    headerFrame.size = self.headerReferenceSize;
    footerFrame.size = self.footerReferenceSize;
    for (NSUInteger section = 0; section < self.styleArray.count; section ++) {
        // header
        areaPos.y = 0;
        headerFrame.origin = areaPos;
        [headerFrameArray addObject:[NSValue valueWithCGRect:headerFrame]];
        if (self.headerFooterPostion == VOMetroHeaderFooterPositionVertical) {
            areaPos.y = self.headerReferenceSize.height;
        }
        else{
            areaPos.x += self.headerReferenceSize.width;
        }
        // area
        areaPos.x += self.sectionInset.right;
        areaPos.y += self.sectionInset.top;
        // cell
        NSArray *sectionStyles     = self.styleArray[section];
        NSUInteger curArea         = 0;
        NSUInteger curUnits        = 0;
        NSMutableArray *sectionAttrsArray = [NSMutableArray array];
        for (NSUInteger row = 0; row < sectionStyles.count; row ++) {
            VOMetroCellStyle style   = [sectionStyles[row] unsignedIntegerValue];
            VOMetroAttributes *attrs = [self imperfectMetroAttributesFromStyle:style];
            CGRect cellFrame         = attrs.frame;
            NSUInteger cellUnits     = attrs.sizeUnits;
            NSUInteger calcCellUnits = MIN(8, cellUnits);
            curUnits                 = (curUnits % calcCellUnits != 0) ? (curUnits/calcCellUnits + 1) * calcCellUnits : curUnits;
            if ((curUnits + curArea * self.unitsPerArea + cellUnits - 1) / self.unitsPerArea == curArea + 1) {
                curArea              += 1;
                curUnits             = 0;
                areaPos.x            += self.areaSize.width + self.areaSpacing;
            }

            cellFrame.origin.x       = areaPos.x + (((curUnits % 8) / 4) * 2 + curUnits % 2) * (self.itemSize.width + self.minimumInteritemSpacing);
            NSUInteger row           = curUnits / 8;
            NSUInteger rowsUnits     = curUnits % 8;
            cellFrame.origin.y       = areaPos.y + (row * 2 + (rowsUnits / 2) % 2) * (self.itemSize.height + self.minimumLineSpacing);
            
            attrs.frame              = cellFrame;
            attrs.area               = curArea;
            attrs.posUnits           = curUnits + curArea * self.unitsPerArea;
            [sectionAttrsArray addObject:attrs];
            curUnits                 += cellUnits;
        }
        [cellAttrsArray addObject:sectionAttrsArray];
        // section结束
        areaPos.x += self.areaSize.width;
        areaPos.x += self.sectionInset.right;
        // footer
        if (self.headerFooterPostion == VOMetroHeaderFooterPositionHorizontal) {
            footerFrame.origin.x = areaPos.x;
            footerFrame.origin.y = headerFrame.origin.y;
            areaPos.x += self.footerReferenceSize.width;
        }
        else{
            footerFrame.origin.x = headerFrame.origin.x;
            footerFrame.origin.y = self.collectionViewContentSize.height - self.footerReferenceSize.height;
        }
        [footerFrameArray addObject:[NSValue valueWithCGRect:footerFrame]];
    }
    self.cellAttrsArray   = cellAttrsArray;
    self.headerFrameArray = headerFrameArray;
    self.footerFrameArray = footerFrameArray;
}

- (NSArray *)indexPathsOfItemsInRect:(CGRect)rect{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger section = 0; section < self.cellAttrsArray.count; section ++) {
        NSArray *sectionAttrs = self.cellAttrsArray[section];
        for (NSUInteger row = 0; row < sectionAttrs.count; row ++) {
            VOMetroAttributes *attrs = sectionAttrs[row];
            if (CGRectIntersectsRect(rect, attrs.frame)) {
                NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
                [indexPaths addObject:path];
            }
        }
    }

    return indexPaths;
}

- (NSArray *)indexPathsOfHeadersInRect:(CGRect)rect{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger section = 0; section < self.headerFrameArray.count; section ++) {
        CGRect headerFrame = [self.headerFrameArray[section] CGRectValue];
            if (headerFrame.size.width > 0 && headerFrame.size.height > 0 && CGRectIntersectsRect(rect, headerFrame)) {
                NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:section];
                [indexPaths addObject:path];
        }
    }
    
    return indexPaths;
}

- (NSArray *)indexPathsOfFootersInRect:(CGRect)rect{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger section = 0; section < self.footerFrameArray.count; section ++) {
        CGRect footerFrame = [self.footerFrameArray[section] CGRectValue];
        if (footerFrame.size.width > 0 && footerFrame.size.height > 0 && CGRectIntersectsRect(rect, footerFrame)) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:section];
            [indexPaths addObject:path];
        }
    }
    
    return indexPaths;
}


- (VOMetroAttributes *)imperfectMetroAttributesFromStyle:(VOMetroCellStyle)style{
    VOMetroAttributes *attrs = [[VOMetroAttributes alloc] init];
    CGRect frame = CGRectZero;
    switch (style) {
        case VOMetroCellSmallSquare:
            attrs.sizeUnits = 1;
            frame.size.width = self.itemSize.width;
            frame.size.height = self.itemSize.height;
            break;
            
        case VOMetroCellRectangle:
            attrs.sizeUnits = 8;
            frame.size.width = self.itemSize.width * 4 + self.minimumInteritemSpacing * 3;
            frame.size.height = self.itemSize.height * 2 + self.minimumLineSpacing;
            break;
            
        case VOMetroCellLargeSquare:
            attrs.sizeUnits = 16;
            frame.size.width = self.itemSize.width * 4  + self.minimumInteritemSpacing * 3;
            frame.size.height = self.itemSize.height * 4  + self.minimumLineSpacing * 3;
            break;
            
        default:
            attrs.sizeUnits = 4;
            frame.size.width = self.itemSize.width * 2 + self.minimumInteritemSpacing;
            frame.size.height = self.itemSize.height * 2 + self.minimumLineSpacing;
            break;
    }
    attrs.frame = frame;
    return attrs;
}

@end
