//
//  PriceView.h
//  ecn-chart
//
//  Created by Stas Buldakov on 01.12.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PriceViewDataSource <NSObject>

-(float)priceForY:(CGFloat)y;

@end

@interface PriceView : UIView

@property (weak, nonatomic) id <PriceViewDataSource> datasource;

-(void)drawPriceInPoint:(CGPoint)point;

@end
