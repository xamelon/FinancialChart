//
//  Candle.h
//  trading-chart
//
//  Created by Stas Buldakov on 03.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Tick;

@interface Candle : UIView

@property (assign, nonatomic) float max;
@property (assign, nonatomic) float min;
@property (assign, nonatomic) float open;
@property (assign, nonatomic) float close;

-(id)initWithMax:(float)max min:(float)min candle:(Tick *)candle frame:(CGRect)frame;

@end
