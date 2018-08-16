//
//  PriceView.h
//  ecn-chart
//
//  Created by Stas Buldakov on 01.12.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Tick;

@protocol PriceViewDataSource <NSObject>

-(float)priceForY:(CGFloat)y;

-(NSNumberFormatter *)numberFormatter;

-(Tick *)tickForIndex:(NSInteger)index;

@end

@interface PriceView : CALayer

@property (weak, nonatomic) id <PriceViewDataSource> datasource;

-(void)drawPriceInPoint:(CGPoint)point;

-(CGFloat)sizeForView;

@end
