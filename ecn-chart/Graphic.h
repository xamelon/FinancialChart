//
//  Graphic.h
//  ecn-chart
//
//  Created by Stas Buldakov on 01.02.18.
//  Copyright © 2018 Galament. All rights reserved.
//
@class Tick;
#import <UIKit/UIKit.h>

typedef enum ChartType : NSInteger {
    ChartTypeLine = 0,
    ChartTypeBar,
    ChartTypeCandle
} ChartType;

@protocol GraphicDataSource <NSObject>
-(CGFloat)getMinValue;
-(CGFloat)getMaxValue;
-(CGFloat)candleWidth;
-(NSInteger)maxCandle;
-(NSInteger)minCandle;
-(Tick *)tickForIndex:(NSInteger)i;
-(Tick *)candleForPoint:(CGPoint)point;
-(NSInteger)candleCount;
-(CGFloat)offsetForCandles;
-(ChartType)chartType;
@end

@interface Graphic : UIView

@property (weak, nonatomic) id <GraphicDataSource> dataSource;
-(void)drawLinesForSelectionPoint:(CGPoint)point;
@end
