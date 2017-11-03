//
//  BGWaterFlowLayout.h
//  BGCollectionView
//
//  Created by user on 15/11/7.
//  Copyright © 2015年 FAL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface doWaterFlowLayout : UICollectionViewLayout
/**
 *  瀑布流有多少列
 */
@property (nonatomic, assign) NSInteger columnNum;
/**
 *  cell与cell之间的水平间距
 */
@property (nonatomic, assign) CGFloat horizontalItemSpacing;
/**
 *  cell与cell之间的垂直间距
 */
@property (nonatomic, assign) CGFloat verticalItemSpacing;
/**
 *  cell之间的宽度
 */
@property (nonatomic, assign) CGFloat itemWidth;
/**
 *  cell之间的高度
 */
@property (nonatomic, assign) CGFloat itemHeight;
/**
 *  内容缩进
 */
@property (nonatomic) UIEdgeInsets contentInset;
/**
 *  头视图的高度，默认为0；为0时，不显示头视图
 */
@property (nonatomic, assign) CGFloat headerHeight;
/**
 *  尾部视图的高度，默认为0；为0时，不显示尾部视图
 */
@property (nonatomic, assign) CGFloat footerHeight;

- (CGSize)layoutFlowContentSize;
@end
