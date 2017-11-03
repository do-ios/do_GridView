//
//  do_GridView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//
#import "do_GridView_UIView.h"
#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doIListData.h"
#import "doTextHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import "doJsonHelper.h"
#import "doUIContainer.h"
#import "doIPage.h"
#import "doIApp.h"
#import "doISourceFS.h"
#import "doEGORefreshTableHeaderView.h"
#import "doWaterFlowLayout.h"
#import "doIUIModuleFactory.h"

static NSString * const doCollectionRefreshHeaderView = @"doCollectionRefreshHeaderView";
@interface do_GridView_UIView()<doEGORefreshTableDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic,strong) doEGORefreshTableHeaderView *egoHeaderView;

@end
@implementation do_GridView_UIView
{
    id<doIListData> _dataArrays;
    NSMutableArray *_dataArrays1;
    
    doWaterFlowLayout *_flowLayout;
    
    UIColor *_selectedColor;
    
    NSMutableArray *_cellTemplatesArray;
    
    NSMutableDictionary *_cellHeights;
    
    BOOL _isHeaderVisible;
    
    UIView *_headerView;
    
    BOOL _isRefreshing;
    
    UILongPressGestureRecognizer *_longPress;
    
    UITapGestureRecognizer *_tapPress;
    
    UICollectionView *_collectionView;
    
    BOOL _pullStatus;
    
    NSInteger _firstVisiblePosition;
    NSInteger _lastVisiblePosition;
    
    int columnNum;
    
    NSMutableDictionary *_identifyDict;
    
    CGSize cellSize;
    NSMutableDictionary *_lastData;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _cellTemplatesArray = [NSMutableArray array];
    _cellHeights = [NSMutableDictionary dictionary];
    _dataArrays1 = [NSMutableArray array];
    
    _isHeaderVisible = NO;
    _headerView = self.egoHeaderView;//默认headerView;
    
    _flowLayout = [[doWaterFlowLayout alloc]init];
    _flowLayout.columnNum = 1;
    _flowLayout.headerHeight = 1;
    
    _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, _model.RealWidth, _model.RealHeight) collectionViewLayout:_flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    //对Cell注册(必须否则程序会挂掉)

    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"UICollectionViewCell0"];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:doCollectionRefreshHeaderView];
    
    //添加长按
    //创建长按手势监听
    _longPress = [[UILongPressGestureRecognizer alloc]
                  initWithTarget:self
                  action:@selector(longPress:)];
    _longPress.minimumPressDuration = .5;
    //将长按手势添加到需要实现长按操作的视图里
    
    _tapPress = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPress:)];
    _tapPress.numberOfTapsRequired = 1;
    _tapPress.numberOfTouchesRequired = 1;
    
    [self addSubview:_collectionView];
    
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.bounces = NO;
    _collectionView.alwaysBounceVertical = YES;
    
    _pullStatus = NO;
    
    _firstVisiblePosition = -1;
    _lastVisiblePosition = -1;
 
    _identifyDict = [NSMutableDictionary dictionary];
    
    cellSize = CGSizeZero;
    _lastData = [NSMutableDictionary dictionary];
}

//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    
    [self removeGestureRecognizer:_longPress];
    [self removeGestureRecognizer:_tapPress];
    _longPress = nil;
    _tapPress = nil;
    
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    [_cellTemplatesArray removeAllObjects];
    _cellTemplatesArray = nil;
    [_cellHeights removeAllObjects];
    _cellHeights = nil;

    [_lastData removeAllObjects];
    _lastData = nil;
    [_dataArrays1 removeAllObjects];
    _dataArrays1 = nil;
    [(doModule*)_dataArrays Dispose];
    
    _flowLayout = nil;
    
    [_collectionView removeFromSuperview];
    _collectionView = nil;
    
    [_identifyDict removeAllObjects];
    _identifyDict = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    //重新调整视图的x,y,w,h
    if([self isAutoHeight]){
        //        float contentheight = _flowLayout.collectionViewContentSize.height;
        float contentheight = [_flowLayout layoutFlowContentSize].height;
        if (_dataArrays1.count==0) {
            contentheight = 0;
        }
        if(contentheight<=0)contentheight = .1;//girdview如果设置为0的时候，会导致数据不加载
        if(self.frame.size.height!=contentheight){
            [self setFrame:CGRectMake(_model.RealX, _model.RealY, _model.RealWidth, contentheight)];
            [_collectionView setFrame:self.bounds];
            [doUIModuleHelper OnResize:_model];
        }
        _collectionView.scrollEnabled = NO;
    }else{
        [doUIModuleHelper OnRedraw:_model];
        _collectionView.frame = self.bounds;
        _collectionView.scrollEnabled = YES;
    }
}
- (BOOL)isAutoHeight
{
    return [[_model GetPropertyValue:@"height"] isEqualToString:@"-1"];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_canScrollToTop:(NSString *)newValue
{
    //自己的代码实现
    BOOL isScroll = [newValue boolValue];
    _collectionView.scrollsToTop = isScroll;
}
- (void)change_headerView:(NSString *)newValue
{
    //自己的代码实现
    id<doIPage> pageModel = _model.CurrentPage;
    doSourceFile *fileName = [pageModel.CurrentApp.SourceFS GetSourceByFileName:newValue];
    @try {
        if(!fileName)
        {
            [NSException raise:@"listview" format:@"无效的headView:%@",newValue,nil];
        }
        doUIContainer *_headerContainer = [[doUIContainer alloc] init:pageModel];
        [_headerContainer LoadFromFile:fileName:nil:nil];
        doUIModule * _headViewModel = _headerContainer.RootView;
        if (_headViewModel == nil)
        {
            [NSException raise:@"listview" format:@"创建view失败",nil];
        }
        UIView *rootView = (UIView*)_headViewModel.CurrentUIModuleView;
        
        if (rootView == nil)
        {
            [NSException raise:@"listview" format:@"创建view失败"];
        }
        if (pageModel.ScriptEngine) {
            [_headerContainer LoadDefalutScriptFile:newValue];
        }
        //得到headerView
        _headerView = rootView;
        CGRect headerFrame = CGRectMake(0, -rootView.bounds.size.height, rootView.bounds.size.width, rootView.bounds.size.height);
        _headerView.frame = headerFrame;
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
    }
}
- (void)change_hSpacing:(NSString *)newValue
{
    //自己的代码实现
    float hSpace = [[doTextHelper Instance] StrToFloat:newValue :0];
    _flowLayout.horizontalItemSpacing = hSpace;
}
- (void)change_isHeaderVisible:(NSString *)newValue
{
    //自己的代码实现
    _isHeaderVisible = [[doTextHelper alloc] StrToBool:newValue :NO];
    _collectionView.bounces = _isHeaderVisible;
}
- (void)change_isShowbar:(NSString *)newValue
{
    //自己的代码实现
    BOOL isShowBar = [[doTextHelper Instance] StrToBool:newValue :YES];
    _collectionView.showsVerticalScrollIndicator = isShowBar;
}
- (void)change_numColumns:(NSString *)newValue
{
    //自己的代码实现
    _flowLayout.itemWidth = 0;
    _flowLayout.columnNum = -1;
    columnNum = [[doTextHelper Instance]StrToInt:newValue :1];
    if (columnNum == 0) {
        columnNum = 1;
    }else if (columnNum < 0) {
        columnNum = -1;
    }
    _flowLayout.columnNum = columnNum;
    if (columnNum==-1) {
        [self caculateItemWidth];
    }
}
- (void)change_selectedColor:(NSString *)newValue
{
    //自己的代码实现
    _selectedColor = [doUIModuleHelper GetColorFromString:newValue :[UIColor clearColor]];
}
- (void)change_templates:(NSString *)newValue
{
    //自己的代码实现
    [_cellTemplatesArray removeAllObjects];
    [_cellTemplatesArray addObjectsFromArray:[newValue componentsSeparatedByString:@","]];
    
    [_identifyDict removeAllObjects];
    for (int i=0;i<_cellTemplatesArray.count;i++) {
        NSString *identify = [NSString stringWithFormat:@"UICollectionViewCell%i",i];
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:identify];
        [_identifyDict setObject:identify forKey:[@(i) stringValue]];
    }
    //    NSString *columns = [_model GetPropertyValue:@"numColumns"];
    //    [self change_numColumns:columns];
    
}
- (void)change_vSpacing:(NSString *)newValue
{
    //自己的代码实现
    float vSpace = [[doTextHelper Instance]StrToFloat:newValue :0];
    _flowLayout.verticalItemSpacing = vSpace;
}

#pragma mark - UICollectionViewDataSource方法
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_dataArrays1 count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSInteger index = indexPath.row;
    id jsonValue = [_dataArrays1 objectAtIndex:index];
    NSString *template = [self getTemplate:jsonValue];
    NSString *cellIndex = [@([doJsonHelper GetOneInteger: jsonValue :@"template" :0]) stringValue];
    NSInteger indexCell = [cellIndex integerValue];
    if(_cellTemplatesArray.count<=0){
        cellIndex = @"0";
    }else if (indexCell>=_cellTemplatesArray.count || indexCell<0){
        cellIndex = @"0";
    }

    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:_identifyDict[cellIndex] forIndexPath:indexPath];
    doUIModule *showCellMode;
    UIView *insertView;
    if (cell.contentView.subviews.count > 0)
    {
        UIView *insertView = cell.contentView.subviews[0];
        showCellMode = [(id<doIUIModuleView>)insertView GetModel];
        [showCellMode SetModelData:jsonValue];
        [showCellMode.CurrentUIModuleView OnRedraw];
    }
    else{
        insertView = [self getInsertView:jsonValue :template];
        [cell.contentView addSubview:insertView];
        cell.contentView.clipsToBounds = YES;
        cell.backgroundColor = [UIColor clearColor];
    }

    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if([kind isEqual:UICollectionElementKindSectionHeader]) {
        //解决多组造成的下拉刷新UI显示异常
        UICollectionReusableView *collectionHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:doCollectionRefreshHeaderView forIndexPath:indexPath];
        
        if (_isHeaderVisible) {//header可见
            //得到设置的headerView
            UIView *headerView = [self getHeaderView];
            if (headerView ==nil) {
                //得到默认的headerView
                headerView = self.egoHeaderView;
            }
            [collectionHeaderView addSubview:headerView];
        }
        return collectionHeaderView;
    }
    return nil;
}

#pragma mark -  method
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    if (cell.contentView.subviews.count==0) {
        return;
    }
    if (![cell.contentView.subviews objectAtIndex:0].backgroundColor) {
        [cell setBackgroundColor:_selectedColor];
    }
    else{
        const CGFloat *components = CGColorGetComponents([cell.contentView.subviews objectAtIndex:0].backgroundColor.CGColor);
        if (components && components[3]==0) {
            [cell setBackgroundColor:_selectedColor];
        }
    }
}

- (void)collectionView:(UICollectionView *)colView  didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor clearColor]];
}

#pragma mark -
#pragma mark - 同步异步方法的实现
- (void)change_items:(NSString *)newValue
{
    NSMutableArray *tmp = [[NSMutableArray arrayWithArray:[doJsonHelper LoadDataFromText : newValue]] mutableCopy];
    
    [_dataArrays1 removeAllObjects];
    _dataArrays1 = tmp;
    [self refresh:nil];
}

//同步
- (void)bindItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine= [parms objectAtIndex:1];
    NSString* _address = [doJsonHelper GetOneText: _dictParas :@"data": nil];
    @try {
        if (_address == nil || _address.length <= 0) [NSException raise:@"doGridView" format:@"未指定相关的gridview data参数！",nil];
        id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
        if (bindingModule == nil) [NSException raise:@"doGridView" format:@"data参数无效！",nil];
        if([bindingModule conformsToProtocol:@protocol(doIListData)])
        {
            if(_dataArrays!= bindingModule)
                _dataArrays = bindingModule;
            if ([_dataArrays GetCount]>0) {
                [self refreshItems:parms];
            }
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception : @"模板为空或者下标越界"];
        doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
        [_result SetException:exception];
    }
}
- (void)rebound:(NSArray *)parms
{
    [UIView setAnimationsEnabled:NO];
    if (_isHeaderVisible) {
        if (_headerView == _egoHeaderView) {
            [_egoHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_collectionView];
        }
        else
        {
            [UIView animateWithDuration:0.2 animations:^{
                _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            }];
        }
    }
    [UIView setAnimationsEnabled:YES];
    _isRefreshing = NO;
    _pullStatus = NO;
    
}
- (void)generateDataArrays1
{
    NSInteger count = [_dataArrays GetCount];
    [_dataArrays1 removeAllObjects];
    _dataArrays1 = [NSMutableArray array];
    int i = 0;
    for (; i<count; i++) {
        [_dataArrays1 addObject:[_dataArrays GetData:i]];
    }
}
- (void)refreshItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    NSArray *indexs = [doJsonHelper GetOneArray:_dictParas :@"indexs"];
    NSMutableArray *tempIndexs = [NSMutableArray array];
    for (NSNumber *index in indexs) {
        NSIndexPath *tempIndexPath = [NSIndexPath indexPathForItem:index.unsignedIntegerValue inSection:0];
        [tempIndexs addObject:tempIndexPath];
    }
    if (_dataArrays1.count>0) {
        _lastData = [_dataArrays1 objectAtIndex:0];
    }
    [self generateDataArrays1];
    
    [self refresh:tempIndexs];
}
- (void)caculateItemWidth
{
    if ([_dataArrays1 count]>0) {
        int tempID = [self getFirstTemplateId];

        //直接写死0，如果0对应的模板是错误的，就不能把其他的显示出来
        CGSize itemSize = [self getEstimatedRowItemSize:tempID];
        _flowLayout.itemHeight = itemSize.height;
        if (columnNum == -1) {
            _flowLayout.itemWidth = itemSize.width;
        }
    }
}
- (void)refresh:(NSArray *)indexs
{
    if (_lastData && _dataArrays1.count>0) {
        if (![_lastData isEqualToDictionary:[_dataArrays1 objectAtIndex:0]]) {
            [self caculateItemWidth];
        }
    }
    if (indexs.count > 0) {
        [_collectionView reloadItemsAtIndexPaths:indexs];
    }
    else
    {
        [_collectionView reloadData];
    }
    [self OnRedraw];
}
//得到有效的模板的frame,模板写错导致获得高度无效
- (int)getFirstTemplateId
{
    int templateIndex;
    for (int i = 0; i < _dataArrays1.count; i ++) {
        id jsonValue = [_dataArrays1 objectAtIndex:i];
        NSString *template = [self getTemplate:jsonValue];
        doSourceFile *source = [[[_model.CurrentPage CurrentApp] SourceFS] GetSourceByFileName:template];
        if (!source) {
            continue;
        }
        id<doIPage> pageModel = _model.CurrentPage;
        doUIContainer *container = [[doUIContainer alloc] init:pageModel];
        @try {
            [container LoadFromFile:source:nil:nil];
            doUIModule *module = container.RootView;
            if (module) {
                templateIndex = i;
                break;
            }
        }
        @catch (NSException *exception) {
            templateIndex = 0;
        }
    }
    return templateIndex;
}

#pragma mark - 私有方法
- (CGSize)getEstimatedRowItemSize:(int)index
{
    @try
    {
        id jsonValue = [_dataArrays1 objectAtIndex:index];
        NSString *template = [self getTemplate:jsonValue];
        UIView *insertView = [self getInsertView:jsonValue :template];
        return insertView.bounds.size;
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
        [_result SetException:exception];
        return CGSizeZero;
    }
}


- (void)longPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (_dataArrays1.count==0||!_dataArrays1) {
        return;
    }
    CGPoint pointTouch = [gestureRecognizer locationInView:_collectionView];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:pointTouch];
        if (indexPath == nil)
        {
            [self fireEvent:@"longTouch1" withPosition:0 withFrame:CGRectZero];
            return;
        }
        else
        {
            [self fireEvent:@"longTouch" withPosition:(int)indexPath.row];
        }
        UICollectionViewLayoutAttributes *attributes = [_collectionView layoutAttributesForItemAtIndexPath:indexPath];
        
        CGRect frame = [_collectionView convertRect:attributes.frame toView:self];
        [self fireEvent:@"longTouch1" withPosition:(int)indexPath.row withFrame:frame];
    }
}

- (void)tapPress:(UITapGestureRecognizer *)gestureRecognizer
{
    if (_dataArrays1.count==0||!_dataArrays1) {
        return;
    }
    CGPoint pointTouch = [gestureRecognizer locationInView:_collectionView];
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:pointTouch];
        if (indexPath == nil)
        {
            [self fireEvent:@"touch1" withPosition:0 withFrame:CGRectZero];
            return;
        }
        else
        {
            [self fireEvent:@"touch" withPosition:(int)indexPath.row];
        }
        UICollectionViewLayoutAttributes *attributes = [_collectionView layoutAttributesForItemAtIndexPath:indexPath];
        
        CGRect frame = [_collectionView convertRect:attributes.frame toView:self];
        [self fireEvent:@"touch1" withPosition:(int)indexPath.row withFrame:frame];
    }
}
- (void)fireEvent:(NSString *)eventName withPosition:(int)position withFrame:(CGRect)frame
{
    int x = frame.origin.x / _model.XZoom;
    int y = frame.origin.y / _model.YZoom;
    
    doInvokeResult *_result = [[doInvokeResult alloc]init];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:@(position) forKey:@"position"];
    [node setObject:@(x) forKey:@"x"];
    [node setObject:@(y) forKey:@"y"];
    [_result SetResultNode:node];
    [_model.EventCenter FireEvent:eventName :_result];
}
- (void)fireEvent:(NSString *)eventName withPosition:(int)position
{
    doInvokeResult* _result = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_result SetResultInteger:position];
    [_model.EventCenter FireEvent:eventName :_result ];
    
}
- (void)fireStateEvent:(NSString *)eventName widthState:(NSString *)state withOffset:(CGFloat)offset
{
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:state forKey:@"state"];
    [node setObject:@(fabs(offset / _model.YZoom)) forKey:@"offset"];
    [_result SetResultNode:node];
    [_model.EventCenter FireEvent:eventName :_result ];
    
}
- (void)fireScrollEvent
{
    if (_isRefreshing) {
        return;
    }
    NSArray * cells = _collectionView.indexPathsForVisibleItems;
    //排序
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
    cells = [cells sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sorter,nil]];
    
    NSIndexPath *firstIndex = cells.firstObject;
    NSIndexPath *lastIndex = cells.lastObject;
    //防止调用多次
    if (_firstVisiblePosition == firstIndex.row && _lastVisiblePosition == lastIndex.row) {
        return;
    }
    _firstVisiblePosition = firstIndex.row;
    _lastVisiblePosition = lastIndex.row;
    
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:@(_firstVisiblePosition) forKey:@"firstVisiblePosition"];
    [node setObject:@(_lastVisiblePosition) forKey:@"lastVisiblePosition"];
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultNode:node];
    [_model.EventCenter FireEvent:@"scroll" :invokeResult];
    
}
- (NSString *)getTemplate:(id)jsonValue
{
    NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
    int cellIndex = [doJsonHelper GetOneInteger: dataNode :@"template" :0];
    NSString* template;
    if(_cellTemplatesArray.count<=0){
        cellIndex = 0;
        [[doServiceContainer Instance].LogEngine WriteError:nil : @"模板不能为空"];
    }else if (cellIndex>=_cellTemplatesArray.count || cellIndex<0){
        cellIndex = 0;
        [[doServiceContainer Instance].LogEngine WriteError:nil : [NSString stringWithFormat:@"下标为%i的模板下标越界",cellIndex]];
    }
    template = _cellTemplatesArray[cellIndex];

    return template;
}
- (UIView *)getInsertView:(id)jsonValue :(NSString *)template
{
    if ([template hasSuffix:@"/"]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil : @"该模板不存在"];
        return nil;
    }
    doUIModule* module ;

    doSourceFile *source = [[[_model.CurrentPage CurrentApp] SourceFS] GetSourceByFileName:template];
    id<doIPage> pageModel = _model.CurrentPage;
    doUIContainer *container = [[doUIContainer alloc] init:pageModel];
    @try {
        [container LoadFromFile:source:nil:nil];
        module = container.RootView;
        
        if (!module) {
            NSException *ext = [[NSException alloc]initWithName:@"gireView" reason:@"模板不存在" userInfo:nil];
            @throw ext;
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception : @"该模板不存在"];
        doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
        [_result SetException:exception];
        return nil;
    }
    [container LoadDefalutScriptFile:template];

    [module SetModelData:jsonValue];
    [module.CurrentUIModuleView OnRedraw];
    
    UIView *view = (UIView *)module.CurrentUIModuleView;
    return view;
}
- (doEGORefreshTableHeaderView *)egoHeaderView
{
    if (!_egoHeaderView) {
        _egoHeaderView = [[doEGORefreshTableHeaderView alloc]initWithFrame:CGRectMake(0, 0 - _model.RealHeight, _model.RealWidth, _model.RealHeight)];
        _egoHeaderView.backgroundColor = [UIColor clearColor];
        _egoHeaderView.delegate = self;
        [_egoHeaderView refreshLastUpdatedDate];
    }
    return _egoHeaderView;
}
- (UIView *)getHeaderView
{
    return _headerView;
}
- (int)getHeaderViewHeight
{
    if (_headerView) {
        if (_headerView == _egoHeaderView) {//默认
            return 60;
        }
        else{
            return roundf(_headerView.bounds.size.height);
        }
    }
    return 0;
}
#pragma  mark - 下拉刷新
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y >=0) {
        [self fireScrollEvent];
    }
    if (_isHeaderVisible) {//header 可见
        int headerHeight = [self getHeaderViewHeight];
        int contentOffset = roundf(scrollView.contentOffset.y);
        //fire state 0
        if (contentOffset < 0) {
            [self fireStateEvent:@"pull" widthState:@"0" withOffset:contentOffset];
        }
        //fire state 1 headerView 的height
        if (contentOffset == -headerHeight) {
            if (!_pullStatus) {
                _pullStatus = YES;
                [self fireStateEvent:@"pull" widthState:@"1" withOffset:contentOffset];
            }
        }
        if (_headerView == _egoHeaderView) {
            [self.egoHeaderView egoRefreshScrollViewDidScroll:scrollView];
        }
    }
    
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _pullStatus = NO;
    [self endDragging:scrollView :YES];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self endDragging:scrollView :NO];
}
- (void)endDragging:(UIScrollView *)scrollView :(BOOL)isFireEvent
{
    if (_isHeaderVisible) {
        CGFloat headerHeight = [self getHeaderViewHeight];
        CGFloat contentOffset = scrollView.contentOffset.y;
        CGFloat headerHeight1 = headerHeight;
        //fire state 2
        if (contentOffset <= -headerHeight1) {
            if (isFireEvent) {
                [self fireStateEvent:@"pull" widthState:@"2" withOffset:contentOffset];
                return;
            }
            UIView *tempHeader = [self getHeaderView];
            if (tempHeader == _egoHeaderView) {
                [_egoHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
            }
            else{
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2];
                scrollView.contentInset = UIEdgeInsetsMake(headerHeight, 0.0f, 0.0f, 0.0f);
                [UIView commitAnimations];
            }
            _isRefreshing = YES;
        }
    }
}

- (void)egoRefreshTableDidTriggerRefresh:(EGORefreshPos)aRefreshPos
{
    _isRefreshing = NO;
}
-(BOOL)egoRefreshTableDataSourceIsLoading:(UIView *)view
{
    return _isRefreshing;
}
-(NSDate *)egoRefreshTableDataSourceLastUpdated:(UIView *)view
{
    return [NSDate date];
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}
- (void)eventName:(NSString *)event :(NSString *)type
{
    if ([event hasPrefix:@"longTouch"]) {
        if ([type isEqualToString:@"on"]) {
            [self addGestureRecognizer:_longPress];
        }else
            [self removeGestureRecognizer:_longPress];
    }else if ([event hasPrefix:@"touch"]) {
        if ([type isEqualToString:@"on"]) {
            [self addGestureRecognizer:_tapPress];
        }else
            [self removeGestureRecognizer:_tapPress];
    }
}
@end
