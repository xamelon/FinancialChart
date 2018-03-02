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


@protocol GraphicHostDatasource <NSObject>

-(NSInteger)numberOfItems;

-(Tick *)candleForIndex:(NSInteger)index;

@end

@protocol GraphicHostDelegate <NSObject>

-(void)needAdditionalData;

@end


@interface GraphicHost : UIView

@property (weak, nonatomic) id <GraphicHostDatasource> dataSource;

@property (weak, nonatomic) id <GraphicHostDelegate> delegate;

@property (assign, nonatomic) NSInteger graphicType;

-(void)insertTick:(Tick *)tick;

-(void)reloadLastTick;

-(void)reloadData;

-(void)setupView;

-(CGFloat)cellSize;

-(Candle *)candleAtPosition:(CGFloat)x;

-(void)scrollToEnd;

@end
