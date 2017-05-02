//
//  UITextView+PlaceholderText.m
//
//  Copyright (c) 2014 Barry Allard
//
//  MIT license

#import "UITextView+PlaceholderText.h"

#import <objc/runtime.h>
#import <objc/message.h>

@implementation UITextView (PlaceholderText)

CGFloat const UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION = 0.25;

static void * const PLACEHOLDER_KEY = (void*)&PLACEHOLDER_KEY;
static void * const PLACEHOLDER_COLOR_KEY = (void*)&PLACEHOLDER_COLOR_KEY;
static void * const PLACEHOLDER_LABEL_KEY = (void*)&PLACEHOLDER_LABEL_KEY;
static void * const PLACEHOLDER_ANIMATION_KEY = (void*)&PLACEHOLDER_ANIMATION_KEY;


static void
swizzle(Class c, SEL orig, SEL new) {
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    
    if (class_addMethod(c,
                        orig,
                        method_getImplementation(newMethod),
                        method_getTypeEncoding(newMethod)))
    {
        class_replaceMethod(c,
                            new,
                            method_getImplementation(origMethod),
                            method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}


+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([self isKindOfClass:UITextView.class]) {
            swizzle(self, @selector(setText:), @selector(newSetText:));
            swizzle(self, @selector(initWithFrame:), @selector(initWithFrameNew:));
        }
    });
}

- (void)setPlaceholder:(NSString *)placeholder
{
    objc_setAssociatedObject(self,
                             PLACEHOLDER_KEY,
                             placeholder,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setup {
#if DRAW_DEBUG
    self.layer.borderColor = UIColor.blueColor.CGColor;
    self.layer.borderWidth = 2;
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setup];
}

- (void)textChanged:(NSNotification *)notification
{
    if (self.placeholder.length == 0) {
        return;
    }
    
    if (self.placeholderAnimation) {
        [UIView animateWithDuration:UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION
                         animations:^{
            [self viewWithTag:999].alpha = (self.text.length == 0) ? 1 : 0;
        }];
    } else {
        [self viewWithTag:999].alpha = (self.text.length == 0) ? 1 : 0;
    }
}

- (id)initWithFrameNew:(CGRect)frame {
    if (self = [self initWithFrameNew:frame]) {
        [self setup];
    }
    return self;
}

- (void)newSetText:(NSString *)text {
    [self newSetText:text];
    [self textChanged:nil];
}

- (NSString *)placeholder
{
    return objc_getAssociatedObject(self, PLACEHOLDER_KEY);
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    objc_setAssociatedObject(self,
                             PLACEHOLDER_COLOR_KEY,
                             placeholderColor,
                             OBJC_ASSOCIATION_ASSIGN);
}

- (UIColor *)placeholderColor
{
    UIColor *result = objc_getAssociatedObject(self, PLACEHOLDER_KEY);
    if (!!result) {
        result = DEFAULT_PLACEHOLDER_COLOR;
    }
    return result;
}


- (UILabel *)newPlaceholderLabel {
    UILabel *placeholderLabel = [[UILabel alloc] initWithFrame:self.bounds];
    
    placeholderLabel.lineBreakMode = NSLineBreakByClipping;
    placeholderLabel.numberOfLines = 1;
    placeholderLabel.font = self.font;
    placeholderLabel.adjustsFontSizeToFitWidth = YES;
    placeholderLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    placeholderLabel.backgroundColor = UIColor.clearColor;
    placeholderLabel.textColor = self.placeholderColor;
#if DRAW_DEBUG
    placeholderLabel.layer.borderColor = UIColor.redColor.CGColor;
    placeholderLabel.layer.borderWidth = 4;
#endif
    placeholderLabel.alpha = 0;
    
    placeholderLabel.tag = 999;
    
    [self addSubview:placeholderLabel];
    
    return placeholderLabel;
}

- (void)setPlaceholderLabel:(UILabel *)placeholderLabel {
    objc_setAssociatedObject(self,
                             PLACEHOLDER_LABEL_KEY,
                             placeholderLabel,
                             OBJC_ASSOCIATION_ASSIGN);
}

- (UILabel *)placeholderLabel {
    UILabel *placeholderLabel = objc_getAssociatedObject(self, PLACEHOLDER_LABEL_KEY);
    if (!placeholderLabel) {
        [self setPlaceholderLabel:placeholderLabel = [self newPlaceholderLabel]];
    }
    return placeholderLabel;
}

- (void)setPlaceholderAnimation:(BOOL)placeholderAnimation {
    objc_setAssociatedObject(self,
                             PLACEHOLDER_ANIMATION_KEY,
                             [NSNumber numberWithBool:placeholderAnimation],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)placeholderAnimation {
    return ((NSNumber *)objc_getAssociatedObject(self, PLACEHOLDER_ANIMATION_KEY)).boolValue;
}

- (void)drawRect:(CGRect)rect
{
    if (self.placeholder && self.placeholder.length > 0) {
        self.placeholderLabel.text = self.placeholder;
        [self sendSubviewToBack:self.placeholderLabel];
        if (self.text && self.text.length == 0) {
            [self viewWithTag:999].alpha = 1;
        }
        self.placeholderLabel.textAlignment = self.textAlignment;
    }
    [super drawRect:rect];
}

@end
