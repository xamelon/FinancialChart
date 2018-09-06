//
//  GraphicHost.h
//  trading-chart
//
//  Created by Stas Buldakov on 03.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Candle;
@class Tick;
@class Graphic;
@class Graph;

@protocol GraphicHostDatasource <NSObject>

@required

-(NSInteger)numberOfItems;

-(Tick *)candleForIndex:(NSInteger)index;

-(NSArray <Tick *> *)dataForRange:(NSRange)range;

@optional

-(NSDateFormatter *)dateFormatter;

-(NSNumberFormatter *)numberFormatter;

@end

@protocol GraphicHostDelegate <NSObject>

-(void)needAdditionalData;

-(void)longTapAtGraphicWithState:(UIGestureRecognizerState)state;

-(void)graphicDidScroll;

@end


@interface GraphicHost : UIView

@property (weak, nonatomic) id <GraphicHostDatasource> dataSource;

@property (weak, nonatomic) id <GraphicHostDelegate> delegate;

@property (assign, nonatomic) NSInteger graphicType;

@property (strong, nonatomic) Graph *mainGraph;

-(void)addIndicator:(__kindof Graphic *)indicator;

-(void)deleteIndicator:(__kindof Graphic *)indicator;

-(NSMutableArray *)indicators;

-(void)insertTick:(Tick *)tick;

-(void)reloadLastTick;

-(NSArray *)dataForRange:(NSRange)range;

-(void)reloadData;

-(void)setupView;

-(CGFloat)cellSize;

-(Candle *)candleAtPosition:(CGFloat)x;

-(void)scrollToEnd;

-(void)scrollToBeginAfterReload;

@end
