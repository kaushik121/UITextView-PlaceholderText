//
//  UITextView+PlaceholderText.h
//
//  Copyright (c) 2014 Barry Allard
//
//  MIT license

#import <UIKit/UIKit.h>

#define DEFAULT_PLACEHOLDER_COLOR (UIColor.lightGrayColor)
#define DRAW_DEBUG 0

@interface UITextView (PlaceholderText)
- (void)setPlaceholder:(NSString *)placeholder;
- (NSString *)placeholder;
- (void)setPlaceholderColor:(UIColor *)placeholderColor;
- (UIColor *)placeholderColor;
- (void)setPlaceholderAnimation:(BOOL)placeholderAnimation;
- (BOOL)placeholderAnimation;
@end
