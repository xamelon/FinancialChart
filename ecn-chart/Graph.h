//
//  Graph.h
//  ecn-chart
//
//  Created by Stas Buldakov on 8/15/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class Tick;
@class Graphic;
@class VerticalAxis;

NS_ASSUME_NONNULL_BEGIN

typedef enum ChartType : NSInteger {
    ChartTypeLine = 0,
    ChartTypeBar,
    ChartTypeCandle
} ChartType;


@protocol GraphDataSource <NSObject>
-(CGFloat)minValue;
-(CGFloat)maxValue;
-(CGFloat)candleWidth;
-(NSInteger)maxCandle;
-(NSInteger)minCandle;
-(Tick *)tickForIndex:(NSInteger)i;
-(Tick *)candleForPoint:(CGPoint)point;
-(NSInteger)candleCount;
-(CGFloat)offsetForCandles;
-(ChartType)chartType;
-(NSRange)currentVisibleRange;
-(NSArray *)dataForRange:(NSRange)range;
-(NSNumberFormatter *)numberFormatter;
@end

@interface Graph : CALayer

@property (strong, nonatomic) VerticalAxis *verticalAxis;
@property (weak, nonatomic) id <GraphDataSource> dataSource;
@property (strong, nonatomic) NSMutableArray <Graphic *> *graphics;
@property (assign, nonatomic) CGFloat topLineWidth;
@property (assign, nonatomic) CGFloat padding;

-(void)reloadData;
-(NSDecimalNumber *)minValue;
-(NSDecimalNumber *)maxValue;

@end

NS_ASSUME_NONNULL_END
