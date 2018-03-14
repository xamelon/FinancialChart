//
//  Tick.h
//  trading-chart
//
//  Created by Stas Buldakov on 07.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tick : NSObject

@property float max;
@property float min;
@property float open;
@property float close;
@property NSInteger date;
@property (strong, nonatomic) NSString *symbolName;

@end
