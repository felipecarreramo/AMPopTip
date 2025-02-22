//
//  AMPopTip.m
//  PopTipDemo
//
//  Created by Andrea Mazzini on 11/07/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "AMPopTip.h"
#import "AMPopTipDefaults.h"
#import "AMPopTip+Draw.h"
#import "AMPopTip+Entrance.h"
#import "AMPopTip+Animation.h"

@interface AMPopTip()

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSAttributedString *attributedText;
@property (nonatomic, strong) NSMutableParagraphStyle *paragraphStyle;
@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRemoveGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeRemoveGesture;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, weak, readwrite) UIView *containerView;
@property (nonatomic, assign, readwrite) AMPopTipDirection direction;
@property (nonatomic, assign, readwrite) CGPoint arrowPosition;
@property (nonatomic, assign, readwrite) BOOL isVisible;
@property (nonatomic, assign) CGRect textBounds;
@property (nonatomic, assign) CGFloat maxWidth;

@end

@implementation AMPopTip

+ (instancetype)popTip {
    return [[AMPopTip alloc] init];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)ignoredFrame {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    _textAlignment = NSTextAlignmentCenter;
    _font = kDefaultFont;
    _textColor = kDefaultTextColor;
    _popoverColor = kDefaultBackgroundColor;
    _borderColor = kDefaultBorderColor;
    _borderWidth = kDefaultBorderWidth;
    _radius = kDefaultRadius;
    _padding = kDefaultPadding;
    _arrowSize = kDefaultArrowSize;
    _animationIn = kDefaultAnimationIn;
    _animationOut = kDefaultAnimationOut;
    _isVisible = NO;
    _shouldDismissOnTapOutside = YES;
    _edgeMargin = kDefaultEdgeMargin;
    _edgeInsets = kDefaultEdgeInsets;
    _rounded = NO;
    _offset = kDefaultOffset;
    _entranceAnimation = AMPopTipEntranceAnimationScale;
    _actionAnimation = AMPopTipActionAnimationNone;
    _actionFloatOffset = kDefaultFloatOffset;
    _actionBounceOffset = kDefaultBounceOffset;
    _actionPulseOffset = kDefaultPulseOffset;
    _actionAnimationIn = kDefaultBounceAnimationIn;
    _actionAnimationOut = kDefaultBounceAnimationOut;
    _tapRemoveGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRemoveGestureHandler)];
    _swipeRemoveGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRemoveGestureHandler)];
}

- (void)layoutSubviews {
    [self setup];
}

- (void)setup {
    if (self.direction == AMPopTipDirectionLeft) {
        self.maxWidth = MIN(self.maxWidth, self.fromFrame.origin.x - self.padding * 2 - self.edgeInsets.left - self.edgeInsets.right - self.arrowSize.width);
    }
    if (self.direction == AMPopTipDirectionRight) {
        self.maxWidth = MIN(self.maxWidth, self.containerView.bounds.size.width - self.fromFrame.origin.x - self.fromFrame.size.width - self.padding * 2 - self.edgeInsets.left - self.edgeInsets.right - self.arrowSize.width);
    }

    if (self.text != nil) {
        self.textBounds = [self.text boundingRectWithSize:(CGSize){self.maxWidth, DBL_MAX }
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName: self.font}
                                                  context:nil];
    } else if (self.attributedText != nil) {
        self.textBounds = [self.attributedText boundingRectWithSize:(CGSize){self.maxWidth, DBL_MAX }
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                            context:nil];
    }

    _textBounds.origin = (CGPoint){self.padding + self.edgeInsets.left, self.padding + self.edgeInsets.top};

    CGRect frame = CGRectZero;
    float offset = self.offset * ((self.direction == AMPopTipDirectionUp || self.direction == AMPopTipDirectionLeft || self.direction == AMPopTipDirectionNone) ? -1 : 1);

    if (self.direction == AMPopTipDirectionUp || self.direction == AMPopTipDirectionDown) {
        frame.size = (CGSize){self.textBounds.size.width + self.padding * 2.0 + self.edgeInsets.left + self.edgeInsets.right, self.textBounds.size.height + self.padding * 2.0 + self.edgeInsets.top + self.edgeInsets.bottom + self.arrowSize.height};

        CGFloat x = self.fromFrame.origin.x + self.fromFrame.size.width / 2 - frame.size.width / 2;
        if (x < 0) { x = self.edgeMargin; }
        if (x + frame.size.width > self.containerView.bounds.size.width) { x = self.containerView.bounds.size.width - frame.size.width - self.edgeMargin; }
        if (self.direction == AMPopTipDirectionDown) {
            frame.origin = (CGPoint){ x, self.fromFrame.origin.y + self.fromFrame.size.height };
        } else {
            frame.origin = (CGPoint){ x, self.fromFrame.origin.y - frame.size.height};
        }

        frame.origin.y += offset;

    } else if (self.direction == AMPopTipDirectionLeft || self.direction == AMPopTipDirectionRight) {
        frame.size = (CGSize){ self.textBounds.size.width + self.padding * 2.0 + self.edgeInsets.left + self.edgeInsets.right + self.arrowSize.height, self.textBounds.size.height + self.padding * 2.0 + self.edgeInsets.top + self.edgeInsets.bottom};

        CGFloat x = 0;
        if (self.direction == AMPopTipDirectionLeft) {
            x = self.fromFrame.origin.x - frame.size.width;
        }
        if (self.direction == AMPopTipDirectionRight) {
            x = self.fromFrame.origin.x + self.fromFrame.size.width;
        }

        x += offset;

        CGFloat y = self.fromFrame.origin.y + self.fromFrame.size.height / 2 - frame.size.height / 2;

        if (y < 0) { y = self.edgeMargin; }
        if (y + frame.size.height > self.containerView.bounds.size.height) { y = self.containerView.bounds.size.height - frame.size.height - self.edgeMargin; }
        frame.origin = (CGPoint){ x, y };
    } else {
        frame.size = (CGSize){ self.textBounds.size.width + self.padding * 2.0 + self.edgeInsets.left + self.edgeInsets.right, self.textBounds.size.height + self.padding * 2.0 + self.edgeInsets.top + self.edgeInsets.bottom };
        frame.origin = (CGPoint){ CGRectGetMidX(self.fromFrame) - frame.size.width / 2, CGRectGetMidY(self.fromFrame) - frame.size.height / 2 + offset };
    }

    frame.size = (CGSize){ frame.size.width + self.borderWidth * 2, frame.size.height + self.borderWidth * 2 };

    switch (self.direction) {
        case AMPopTipDirectionNone: {
            self.arrowPosition = CGPointZero;
            self.layer.anchorPoint = (CGPoint){ 0.5, 0.5 };
            self.layer.position = (CGPoint){ CGRectGetMidX(self.fromFrame), CGRectGetMidY(self.fromFrame) };
            break;
        }
        case AMPopTipDirectionDown: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x + self.fromFrame.size.width / 2 - frame.origin.x,
                self.fromFrame.origin.y + self.fromFrame.size.height - frame.origin.y + offset
            };
            CGFloat anchor = self.arrowPosition.x / frame.size.width;
            _textBounds.origin = (CGPoint){ self.textBounds.origin.x, self.textBounds.origin.y + self.arrowSize.height };
            self.layer.anchorPoint = (CGPoint){ anchor, 0 };
            self.layer.position = (CGPoint){ self.layer.position.x + frame.size.width * anchor, self.layer.position.y - frame.size.height / 2 };

            break;
        }
        case AMPopTipDirectionUp: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x + self.fromFrame.size.width / 2 - frame.origin.x,
                frame.size.height
            };
            CGFloat anchor = self.arrowPosition.x / frame.size.width;
            self.layer.anchorPoint = (CGPoint){ anchor, 1 };
            self.layer.position = (CGPoint){ self.layer.position.x + frame.size.width * anchor, self.layer.position.y + frame.size.height / 2 };

            break;
        }
        case AMPopTipDirectionLeft: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x - frame.origin.x + offset,
                self.fromFrame.origin.y + self.fromFrame.size.height / 2 - frame.origin.y
            };
            CGFloat anchor = self.arrowPosition.y / frame.size.height;
            self.layer.anchorPoint = (CGPoint){ 1, anchor };
            self.layer.position = (CGPoint){ self.layer.position.x - frame.size.width / 2, self.layer.position.y + frame.size.height * anchor };

            break;
        }
        case AMPopTipDirectionRight: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x + self.fromFrame.size.width - frame.origin.x + offset,
                self.fromFrame.origin.y + self.fromFrame.size.height / 2 - frame.origin.y
            };
            _textBounds.origin = (CGPoint){ self.textBounds.origin.x + self.arrowSize.height, self.textBounds.origin.y };
            CGFloat anchor = self.arrowPosition.y / frame.size.height;
            self.layer.anchorPoint = (CGPoint){ 0, anchor };
            self.layer.position = (CGPoint){ self.layer.position.x + frame.size.width / 2, self.layer.position.y + frame.size.height * anchor };

            break;
        }
    }

    self.backgroundColor = [UIColor clearColor];
    self.frame = frame;

    self.gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:self.gestureRecognizer];
    [self setNeedsDisplay];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.shouldDismissOnTap) {
        [self hide];
    }
    if (self.tapHandler) {
        self.tapHandler();
    }
}

- (void)tapRemoveGestureHandler {
    if (self.shouldDismissOnTapOutside) {
        [self hide];
    }
}

- (void)swipeRemoveGestureHandler {
    if (self.shouldDismissOnSwipeOutside) {
        [self hide];
    }
}

- (void)drawRect:(CGRect)rect {

    if (self.isRounded) {
        BOOL showHorizontally = self.direction == AMPopTipDirectionLeft || self.direction == AMPopTipDirectionRight;
        self.radius = (self.frame.size.height - (showHorizontally ? 0 : self.arrowSize.height)) / 2 ;
    }

    UIBezierPath *path = [self pathWithRect:rect direction:self.direction];

    [self.popoverColor setFill];
    [path fill];

    [self.borderColor setStroke];
    [path setLineWidth:self.borderWidth];
    [path stroke];

    self.paragraphStyle.alignment = self.textAlignment;

    NSDictionary *titleAttributes = @{
                                      NSParagraphStyleAttributeName: self.paragraphStyle,
                                      NSFontAttributeName: self.font,
                                      NSForegroundColorAttributeName: self.textColor
                                      };

    if (self.text != nil) {
        [self.text drawInRect:self.textBounds withAttributes:titleAttributes];
    } else if (self.attributedText != nil) {
        [self.attributedText drawInRect:self.textBounds];
    }
}

- (void)show {
    [self setNeedsLayout];
    __weak AMPopTip *weakSelf = self;
    [self performEntranceAnimation:^{
        weakSelf.isVisible = YES;
        [self.containerView addGestureRecognizer:self.tapRemoveGesture];
        [self.containerView addGestureRecognizer:self.swipeRemoveGesture];
        if (self.appearHandler) {
            self.appearHandler();
        }
        if (self.actionAnimation != AMPopTipActionAnimationNone) {
            [self startActionAnimation];
        }
    }];
}

- (void)showText:(NSString *)text direction:(AMPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame {
    self.attributedText = nil;
    self.text = text;
    self.accessibilityLabel = text;
    self.direction = direction;
    self.containerView = view;
    self.maxWidth = maxWidth;
    _fromFrame = frame;

    [self show];
}

- (void)showAttributedText:(NSAttributedString *)text direction:(AMPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame {
    self.text = nil;
    self.attributedText = text;
    self.accessibilityLabel = [text string];
    self.direction = direction;
    self.containerView = view;
    self.maxWidth = maxWidth;
    _fromFrame = frame;

    [self show];
}

- (void)setFromFrame:(CGRect)fromFrame {
    _fromFrame = fromFrame;
    [self setup];
}

- (void)showText:(NSString *)text direction:(AMPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame duration:(NSTimeInterval)interval {
    [self showText:text direction:direction maxWidth:maxWidth inView:view fromFrame:frame];
    [self.dismissTimer invalidate];
    if (interval > 0) {
        self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(hide)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}

- (void)showAttributedText:(NSAttributedString *)text direction:(AMPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame duration:(NSTimeInterval)interval {
    [self showAttributedText:text direction:direction maxWidth:maxWidth inView:view fromFrame:frame];
    [self.dismissTimer invalidate];
    if(interval > 0){
        self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(hide)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}

- (void)hide {
    [self.dismissTimer invalidate];
    self.dismissTimer = nil;
    [self.containerView removeGestureRecognizer:self.tapRemoveGesture];
    [self.containerView removeGestureRecognizer:self.swipeRemoveGesture];
    if (self.superview) {
        self.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:self.animationOut delay:self.delayOut options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.transform = CGAffineTransformMakeScale(0.000001, 0.000001);
        } completion:^(BOOL finished) {
            [self stopActionAnimation];
            [self removeFromSuperview];
            [self.layer removeAllAnimations];
            self.transform = CGAffineTransformIdentity;
            self->_isVisible = NO;
            if (self.dismissHandler) {
                self.dismissHandler();
            }
        }];
    }
}

- (void)updateText:(NSString *)text {
    self.text = text;
    self.accessibilityLabel = text;
    [self setNeedsLayout];
}

- (void) updateAttributedText:(NSAttributedString *) attributedString {
    self.attributedText = attributedString;
    self.accessibilityLabel = [attributedString string];
    [self setNeedsLayout];
}

- (void)startActionAnimation {
    [self performActionAnimation];
}

- (void)stopActionAnimation {
    [self dismissActionAnimation];
}

- (void)setShouldDismissOnTapOutside:(BOOL)shouldDismissOnTapOutside {
    _shouldDismissOnTapOutside = shouldDismissOnTapOutside;
    _tapRemoveGesture.enabled = shouldDismissOnTapOutside;
}

- (void)setShouldDismissOnSwipeOutside:(BOOL)shouldDismissOnSwipeOutside {
    _shouldDismissOnSwipeOutside = shouldDismissOnSwipeOutside;
    _swipeRemoveGesture.enabled = shouldDismissOnSwipeOutside;
}

- (void)setSwipeRemoveGestureDirection:(UISwipeGestureRecognizerDirection)swipeRemoveGestureDirection {
    _swipeRemoveGestureDirection = swipeRemoveGestureDirection;
    _swipeRemoveGesture.direction = swipeRemoveGestureDirection;
}

- (void)dealloc {
    [_tapRemoveGesture removeTarget:self action:@selector(tapRemoveGestureHandler)];
    _tapRemoveGesture = nil;

    [_swipeRemoveGesture removeTarget:self action:@selector(swipeRemoveGestureHandler)];
    _swipeRemoveGesture = nil;
}

@end
