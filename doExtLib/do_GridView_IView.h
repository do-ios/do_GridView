//
//  do_GridView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_GridView_IView <NSObject>

@required
//属性方法
- (void)change_canScrollToTop:(NSString *)newValue;
- (void)change_headerView:(NSString *)newValue;
- (void)change_hSpacing:(NSString *)newValue;
- (void)change_isHeaderVisible:(NSString *)newValue;
- (void)change_isShowbar:(NSString *)newValue;
- (void)change_numColumns:(NSString *)newValue;
- (void)change_selectedColor:(NSString *)newValue;
- (void)change_templates:(NSString *)newValue;
- (void)change_vSpacing:(NSString *)newValue;
- (void)change_items:(NSString *)newValue;

//同步或异步方法
- (void)bindItems:(NSArray *)parms;
- (void)rebound:(NSArray *)parms;
- (void)refreshItems:(NSArray *)parms;


@end