//
//  Graphic.h
//  ecn-chart
//
//  Created by Stas Buldakov on 01.02.18.
//  Copyright © 2018 Galament. All rights reserved.
//
@class Tick;
#import <UIKit/UIKit.h>
@protocol GraphicDataSource <NSObject>
-(CGFloat)getMinValue;
-(CGFloat)getMaxValue;
-(CGFloat)candleWidth;
-(NSInteger)maxCandle;
-(NSInteger)minCandle;
-(Tick *)tickForIndex:(NSInteger)i;
-(NSInteger)candleCount;
-(CGFloat)offsetForCandles;
@end

@interface Graphic : UIView

@property (weak, nonatomic) id <GraphicDataSource> dataSource;

@end
