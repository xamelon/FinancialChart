//
//  TimeLine.h
//  ecn-chart
//
//  Created by Stas Buldakov on 30.11.17.
//  Copyright © 2017 Galament. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphicHost;

@protocol GraphicDataSource;

@protocol TimeLineDataSource <NSObject>

-(NSDate *)dateAtPosition:(CGFloat)x;

-(NSDateFormatter *)dateFormatter;

-(NSInteger)countOfTwoCells;

@end

@interface TimeLine : CALayer

@property (weak, nonatomic) id <TimeLineDataSource, GraphicDataSource> dataSource;

@end
