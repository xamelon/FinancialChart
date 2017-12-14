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

typedef enum {
    PeriodTypeM1, //minute
    PeriodTypeM5,
    PeriodTypeM15,
    PeriodTypeM30,
    PeriodTypeH1, //hour
    PeriodTypeH4,
    PeriodTypeD1, //day
    PeriodTypeW1, //week
    PeriodTypeMN //month
    
} PeriodType;

@protocol GraphicHostDatasource <NSObject>

-(NSInteger)numberOfItems;

-(PeriodType)periodType;

-(Tick *)candleForIndex:(NSInteger)index;

@end

@protocol GraphicHostDelegate <NSObject>

-(void)needAdditionalData;

@end


@interface GraphicHost : UIView

@property (weak, nonatomic) id <GraphicHostDatasource> dataSource;

@property (weak, nonatomic) id <GraphicHostDelegate> delegate;

-(void)reloadData;

-(void)setupView;

-(CGFloat)cellSize;

-(Candle *)candleAtPosition:(CGFloat)x;

@end
