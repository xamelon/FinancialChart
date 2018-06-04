//
//  QuoteHelper.m
//  ecn-terminal
//
//  Created by Stas Buldakov on 31.01.18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "QuoteHelper.h"

@implementation QuoteHelper

+(int)lengthForFloat:(float)number {
    int tort = (int)number;
    int numberLength = 0;
    do {
        numberLength++;
        tort /= 10;
    } while(tort);
    return numberLength;
}

+(int)precisionForFloat:(float)number {
    int precision = [self lengthForFloat:number];
    return 5-precision > 0 ? 5-precision : 0;
}

+ (int)countDigits:(double)num {
    int rv = 0;
    const double insignificantDigit = 8; // <-- since you want 18 significant digits
    double intpart, fracpart;
    fracpart = modf(num, &intpart); // <-- Breaks num into an integral and a fractional part.
    
    // While the fractional part is greater than 0.0000001f,
    // multiply it by 10 and count each iteration
    while ((fabs(fracpart) > 0.0000001f) && (rv < insignificantDigit)) {
        num *= 10;
        fracpart = modf(num, &intpart);
        rv++;
    }
    return rv;
}

+(NSDecimalNumber *)decimalNumberFromDouble:(double)num {
    NSDecimalNumber *decimalNumber = [NSDecimalNumber decimalNumberWithMantissa:(num * pow(10, 8)) exponent:-8 isNegative:num < 0 ? YES : NO];
    
    
    return decimalNumber;
}

+(NSString *)stringFromDecimalNumber:(NSDecimalNumber *)number {
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setPositiveFormat:@"#.####*0"];
    
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    [nf setDecimalSeparator:@"."];
    [nf setRoundingMode:NSNumberFormatterRoundUp];
    [nf setMaximumSignificantDigits:5];
    [nf setAllowsFloats:YES];
    [nf setAlwaysShowsDecimalSeparator:YES];
    return [nf stringFromNumber:number];
}

+(NSString *)symbolForCurrency:(NSString *)currency {
    if([currency isEqualToString:@"USD"]) {
        return @"$";
    } else if([currency isEqualToString:@"RUB"]) {
        return @"₽";
    }
    return @"$";
}



@end
