//
//  BaseIndicator.h
//  ecn-chart
//
//  Created by Stas Buldakov on 8/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
@class Tick;

@protocol IndicatorDataSource <NSObject>

-(NSRange)currentVisibleRange;
-(Tick *)tickForIndex:(NSInteger)index;
-(CGFloat)offsetForCandles;
-(CGFloat)candleWidth;
-(CGFloat)maxValue;
-(CGFloat)minValue;
-(NSInteger)candleCount;

@end

@interface BaseIndicator : CALayer

@property (weak, nonatomic) id <IndicatorDataSource> dataSource;

-(CGFloat)maxValueInRange:(NSRange)range;
-(CGFloat)minValueInRange:(NSRange)range;


@end
