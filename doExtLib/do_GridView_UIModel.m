//
//  do_GridView_Model.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_GridView_UIModel.h"
#import "doProperty.h"
#import "doIEventCenter.h"
#import "do_GridView_UIView.h"

@interface do_GridView_UIModel()<doIEventCenter>

@end

@implementation do_GridView_UIModel

#pragma mark - 注册属性（--属性定义--）
/*
[self RegistProperty:[[doProperty alloc]init:@"属性名" :属性类型 :@"默认值" : BOOL:是否支持代码修改属性]];
 */
-(void)OnInit
{
    [super OnInit];    
    //属性声明
	[self RegistProperty:[[doProperty alloc]init:@"canScrollToTop" :Bool :@"true" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"headerView" :String :@"" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"hSpacing" :Number :@"" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"isHeaderVisible" :Bool :@"false" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"isShowbar" :Bool :@"true" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"numColumns" :Number :@"1" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"selectedColor" :String :@"" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"templates" :String :@"" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"vSpacing" :Number :@"" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"items" :String :@"" :NO]];
}
- (void)eventOn:(NSString *)onEvent
{
    [((do_GridView_UIView *)self.CurrentUIModuleView) eventName:onEvent :@"on"];
}

- (void)eventOff:(NSString *)offEvent
{
    [((do_GridView_UIView *)self.CurrentUIModuleView) eventName:offEvent :@"off"];
}
@end