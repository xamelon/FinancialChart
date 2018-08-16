//
//  Graphic.h
//  ecn-chart
//
//  Created by Stas Buldakov on 01.02.18.
//  Copyright © 2018 Galament. All rights reserved.
//
@class Tick;
#import <UIKit/UIKit.h>
#import "Graphic.h"

@interface CandleGraphic : Graphic
-(void)drawLinesForSelectionPoint:(CGPoint)point;
@end
