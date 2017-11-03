//
//  BGWaterFlowLayout.m
//  BGCollectionView
//
//  Created by user on 15/11/7.
//  Copyright © 2015年 FAL. All rights reserved.
//

#import "doWaterFlowLayout.h"

#pragma mark - BGWaterFlowLayout

@interface doWaterFlowLayout ()
@property (nonatomic, strong) NSMutableDictionary *cellLayoutInfoDic;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, strong) UICollectionViewLayoutAttributes *headerLayoutAttributes;
@property (nonatomic, strong) UICollectionViewLayoutAttributes *footerLayoutAttributes;
@end

@implementation doWaterFlowLayout

#pragma mark - 重写父类方法
- (void)prepareLayout{
    [super prepareLayout];
    
    self.contentSize = [self layoutFlowContentSize];

}

- (CGSize)layoutFlowContentSize
{
    if (_columnNum != -1) {
        _itemWidth = (self.collectionView.frame.size.width - (self.horizontalItemSpacing * (_columnNum - 1))) / _columnNum;
    }
    else
    {
        if (_itemWidth>1) {
            //如果列数为-1，则重新计算列宽，以便在默认情况下也可以显示间距。
            _columnNum = self.collectionView.frame.size.width / (_itemWidth + self.contentInset.left + self.contentInset.right);
            _itemWidth = (self.collectionView.frame.size.width - (self.horizontalItemSpacing * (_columnNum - 1))) / _columnNum;
        }
    }
    //头视图
    if(self.headerHeight > 0){
        self.headerLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        self.headerLayoutAttributes.frame = CGRectMake(0, 0, self.collectionView.frame.size.width, self.headerHeight);
    }
    NSInteger numItems = [self.collectionView numberOfItemsInSection:0];
    if (!self.cellLayoutInfoDic) {
        self.cellLayoutInfoDic = [NSMutableDictionary dictionary];
    }
    if (numItems>0) {
        [self.cellLayoutInfoDic removeAllObjects];
    }
    for (int num = 0; num < numItems; num ++) {
        int row = num / _columnNum;//行号
        int col = num % _columnNum;//列号
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:num inSection:0];
        UICollectionViewLayoutAttributes *itemAttributes = _cellLayoutInfoDic[indexPath];
        if (!itemAttributes) {
            itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        }
        
        CGFloat x = col * (_itemWidth + _horizontalItemSpacing);
        CGFloat y = row * (_itemHeight + _verticalItemSpacing);
        
        CGRect r = CGRectMake(x, y, _itemWidth, _itemHeight);
        itemAttributes.frame = r;

        [_cellLayoutInfoDic setObject:itemAttributes forKey:indexPath];
    }
    NSArray *atts = _cellLayoutInfoDic.allKeys;
    
    //取最后一个的坐标来获得最大Y值
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"row" ascending:YES];
    atts = [atts sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sortDescriptor,nil]];
    UICollectionViewLayoutAttributes *test = [_cellLayoutInfoDic objectForKey:atts.lastObject];
    CGFloat maxY = CGRectGetMaxY(test.frame);
    
    return CGSizeMake(self.collectionView.bounds.size.width, maxY);
}

- (CGSize)collectionViewContentSize{
    return self.contentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *returnAttry = [NSMutableArray array];

    NSInteger numItems = [self.collectionView numberOfItemsInSection:0];
    for (int i=0; i<numItems; i++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        [returnAttry addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
    //添加headerView
    [returnAttry addObject:self.headerLayoutAttributes];
    return returnAttry;
}
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.cellLayoutInfoDic objectForKey:indexPath];
}
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    return attributes;
}

#pragma mark - set method
- (void)setHorizontalItemSpacing:(CGFloat)horizontalItemSpacing{
    _horizontalItemSpacing = horizontalItemSpacing;
    [self invalidateLayout];
}

- (void)setVerticalItemSpacing:(CGFloat)verticalItemSpacing{
    _verticalItemSpacing = verticalItemSpacing;
    [self invalidateLayout];
}

- (void)setItemWidth:(CGFloat)itemWidth{
    _itemWidth = itemWidth;
    [self invalidateLayout];
}
- (void)setItemHeight:(CGFloat)itemHeight
{
    _itemHeight = itemHeight;
    [self invalidateLayout];
}
- (void)setColumnNum:(NSInteger)columnNum{
    _columnNum = columnNum;
    [self invalidateLayout];
}

- (void)setContentInset:(UIEdgeInsets)contentInset{
    _contentInset = contentInset;
    [self invalidateLayout];
}

- (void)setHeaderHeight:(CGFloat)headerHeight{
    _headerHeight = headerHeight;
    [self invalidateLayout];
}

- (void)setFooterHeight:(CGFloat)footerHeight{
    _footerHeight = footerHeight;
    [self invalidateLayout];
}
@end
