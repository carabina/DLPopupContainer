//
//  DLPopupContainer.m
//  PopupContainer
//
//  Created by Dalang on 2018/2/5.
//  Copyright © 2018年 Dalang. All rights reserved.
//

#import "DLPopupContainer.h"

static NSInteger const kAnimationOptionCurveIOS7 = (7 << 16);

DLPopupContainerLayout DLPopupContainerLayoutMake(DLPopupContainerHorizontalLayout horizontal, DLPopupContainerVerticalLayout vertical) {
    DLPopupContainerLayout layout;
    layout.horizontal = horizontal;
    layout.vertical = vertical;
    return layout;
}

static const DLPopupContainerLayout DLPopupContainerLayoutCenter = {DLPopupContainerHorizontalLayoutCenter, DLPopupContainerVerticalLayoutCenter};


@interface NSValue (DLPopupContainerLayout)
+ (NSValue *)valueWithPopupContainerLayout:(DLPopupContainerLayout)layout;

- (DLPopupContainerLayout)DLPopupContainerLayoutValue;
@end

@interface DLPopupContainer () {
    // views
    UIView *_backgroundView;
    UIView *_containerView;
    
    // state flags
    BOOL _isBeingShown;
    BOOL _isShowing;
    BOOL _isBeingDismissed;
    CGRect _keyboardRect;
}

@property UIVisualEffectView *_blurEffectView;

- (void)updateForInterfaceOrientation;

- (void)didChangeStatusBarOrientation:(NSNotification *)notification;

- (void)dismiss;

@end

@implementation DLPopupContainer

@synthesize backgroundView = _backgroundView;
@synthesize containerView = _containerView;
@synthesize isBeingShown = _isBeingShown;
@synthesize isShowing = _isShowing;
@synthesize isBeingDismissed = _isBeingDismissed;

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // stop listening to notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (instancetype)init
{
    return [self initWithFrame:[UIScreen mainScreen].bounds];
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
        
        self.shouldDismissOnBackgroundTouch = YES;
        self.shouldDismissOnContentTouch = NO;
        
        self.showType = DLPopupContainerShowTypeShrinkIn;
        self.dismissType = DLPopupContainerDismissTypeShrinkOut;
        self.maskType = DLPopupContainerMaskTypeDimmed;
        self.dimmedMaskAlpha = 0.5;
        
        _isBeingShown = NO;
        _isShowing = NO;
        _isBeingDismissed = NO;
        
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor clearColor];
        _backgroundView.userInteractionEnabled = NO;
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _backgroundView.frame = self.bounds;
        
        _containerView = [[UIView alloc] init];
        _containerView.autoresizesSubviews = NO;
        _containerView.userInteractionEnabled = YES;
        _containerView.backgroundColor = [UIColor clearColor];
        
        [self addSubview:_backgroundView];
        [self addSubview:_containerView];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarFrameNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (CGRectContainsPoint(_keyboardRect, point)) {
        return nil;
    }
    
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self || [NSStringFromClass([hitView class]) isEqualToString:@"_UIVisualEffectContentView"]) {
        if (_shouldDismissOnBackgroundTouch) {
            [self dismiss:YES];
        }
        
        if (_maskType == DLPopupContainerMaskTypeNone) {
            return nil;
        } else {
            return hitView;
        }
    } else {
        if ([hitView isDescendantOfView:_containerView]) {
            if (_shouldDismissOnContentTouch) {
                [self dismiss:YES];
            }
        }
        return hitView;
    }
}


#pragma mark - Class Public

+ (instancetype)popupContainerWithContentView:(UIView *)contentView
{
    DLPopupContainer *popup = [[[self class] alloc] init];
    popup.contentView = contentView;
    return popup;
}


+ (instancetype)popupContainerWithContentView:(UIView *)contentView
                                     showType:(DLPopupContainerShowType)showType
                                  dismissType:(DLPopupContainerDismissType)dismissType
                                     maskType:(DLPopupContainerMaskType)maskType
               shouldDismissOnBackgroundTouch:(BOOL)shouldDismissOnBackgroundTouch
                  shouldDismissOnContentTouch:(BOOL)shouldDismissOnContentTouch
{
    DLPopupContainer *popup = [[[self class] alloc] init];
    popup.contentView = contentView;
    popup.showType = showType;
    popup.dismissType = dismissType;
    popup.maskType = maskType;
    popup.shouldDismissOnBackgroundTouch = shouldDismissOnBackgroundTouch;
    popup.shouldDismissOnContentTouch = shouldDismissOnContentTouch;
    return popup;
}

+ (void)dismissAllPopups {
    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in windows) {
        [window forEachPopupDoBlock:^(DLPopupContainer *popup) {
            [popup dismiss:NO];
        }];
    }
}


#pragma mark - Public

- (void)show {
    [self showWithLayout:DLPopupContainerLayoutCenter];
}


- (void)showWithLayout:(DLPopupContainerLayout)layout {
    [self showWithLayout:layout duration:0.0];
}


- (void)showWithDuration:(NSTimeInterval)duration {
    [self showWithLayout:DLPopupContainerLayoutCenter duration:duration];
}

- (void)showWithLayout:(DLPopupContainerLayout)layout
                inView:(UIView*) view {
    NSDictionary *parameters = @{
                                 @"layout" : [NSValue valueWithPopupContainerLayout:layout],
                                 @"view": view
                                 };
    [self showWithParameters:parameters];
}

- (void)showWithLayout:(DLPopupContainerLayout)layout duration:(NSTimeInterval)duration {
    NSDictionary *parameters = @{
                                 @"layout" : [NSValue valueWithPopupContainerLayout:layout],
                                 @"duration" : @(duration)
                                 };
    [self showWithParameters:parameters];
}


- (void)showAtCenter:(CGPoint)center inView:(UIView *)view {
    [self showAtCenter:center inView:view withDuration:0.0];
}


- (void)showAtCenter:(CGPoint)center inView:(UIView *)view withDuration:(NSTimeInterval)duration {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:[NSValue valueWithCGPoint:center] forKey:@"center"];
    [parameters setValue:@(duration) forKey:@"duration"];
    [parameters setValue:view forKey:@"view"];
    [self showWithParameters:[NSDictionary dictionaryWithDictionary:parameters]];
}


- (void)dismiss:(BOOL)animated {
    
    if (_isShowing && !_isBeingDismissed) {
        _isBeingShown = NO;
        _isShowing = NO;
        _isBeingDismissed = YES;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
        
        [self willStartDismissing];
        
        if (self.willStartDismissingCompletion != nil) {
            self.willStartDismissingCompletion();
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            void (^backgroundAnimationBlock)(void) = ^(void) {
                _backgroundView.alpha = 0.0;
            };
            
            if (animated && (_showType != DLPopupContainerShowTypeNone)) {
                
                [UIView animateWithDuration:0.15
                                      delay:0
                                    options:UIViewAnimationOptionCurveLinear
                                 animations:backgroundAnimationBlock
                                 completion:NULL];
            } else {
                backgroundAnimationBlock();
            }
            
            
            void (^completionBlock)(BOOL) = ^(BOOL finished) {
                
                [self removeFromSuperview];
                
                _isBeingShown = NO;
                _isShowing = NO;
                _isBeingDismissed = NO;
                
                [self didFinishDismissing];
                
                if (self.didFinishDismissingCompletion != nil) {
                    self.didFinishDismissingCompletion();
                }
            };
            
            NSTimeInterval bounce1Duration = 0.13;
            NSTimeInterval bounce2Duration = (bounce1Duration * 2.0);
            
            if (animated) {
                switch (_dismissType) {
                    case DLPopupContainerDismissTypeFadeOut: {
                        [UIView animateWithDuration:0.15
                                              delay:0
                                            options:UIViewAnimationOptionCurveLinear
                                         animations:^{
                                             _containerView.alpha = 0.0;
                                         } completion:completionBlock];
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeGrowOut: {
                        [UIView animateWithDuration:0.15
                                              delay:0
                                            options:(UIViewAnimationOptions) kAnimationOptionCurveIOS7
                                         animations:^{
                                             _containerView.alpha = 0.0;
                                             _containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                                         } completion:completionBlock];
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeShrinkOut: {
                        [UIView animateWithDuration:0.15
                                              delay:0
                                            options:(UIViewAnimationOptions) kAnimationOptionCurveIOS7
                                         animations:^{
                                             _containerView.alpha = 0.0;
                                             _containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                                         } completion:completionBlock];
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeSlideOutToTop: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:(UIViewAnimationOptions) kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.y = -CGRectGetHeight(finalFrame);
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeSlideOutToBottom: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:(UIViewAnimationOptions) kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.y = CGRectGetHeight(self.bounds);
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeSlideOutToLeft: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:(UIViewAnimationOptions) kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.x = -CGRectGetWidth(finalFrame);
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeSlideOutToRight: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:(UIViewAnimationOptions) kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.x = CGRectGetWidth(self.bounds);
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeBounceOut: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void) {
                                             _containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                                         }
                                         completion:^(BOOL finished) {
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void) {
                                                                  _containerView.alpha = 0.0;
                                                                  _containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                                                              }
                                                              completion:completionBlock];
                                         }];
                        
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeBounceOutToTop: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void) {
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.y += 40.0;
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished) {
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void) {
                                                                  CGRect finalFrame = _containerView.frame;
                                                                  finalFrame.origin.y = -CGRectGetHeight(finalFrame);
                                                                  _containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeBounceOutToBottom: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void) {
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.y -= 40.0;
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished) {
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void) {
                                                                  CGRect finalFrame = _containerView.frame;
                                                                  finalFrame.origin.y = CGRectGetHeight(self.bounds);
                                                                  _containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeBounceOutToLeft: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void) {
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.x += 40.0;
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished) {
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void) {
                                                                  CGRect finalFrame = _containerView.frame;
                                                                  finalFrame.origin.x = -CGRectGetWidth(finalFrame);
                                                                  _containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        break;
                    }
                        
                    case DLPopupContainerDismissTypeBounceOutToRight: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void) {
                                             CGRect finalFrame = _containerView.frame;
                                             finalFrame.origin.x -= 40.0;
                                             _containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished) {
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void) {
                                                                  CGRect finalFrame = _containerView.frame;
                                                                  finalFrame.origin.x = CGRectGetWidth(self.bounds);
                                                                  _containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        break;
                    }
                        
                    default: {
                        self.containerView.alpha = 0.0;
                        completionBlock(YES);
                        break;
                    }
                }
            } else {
                self.containerView.alpha = 0.0;
                completionBlock(YES);
            }
            
        });
    }
}


#pragma mark - Private

- (void)showWithParameters:(NSDictionary *)parameters
{
    if (!_isBeingShown && !_isShowing && !_isBeingDismissed) {
        _isBeingShown = YES;
        _isShowing = NO;
        _isBeingDismissed = NO;
        
        [self willStartShowing];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIView *destView;
            if (!self.superview) {
                destView = [parameters valueForKey:@"view"];
                if (destView == nil) {
                    NSEnumerator *frontToBackWindows = [[UIApplication sharedApplication].windows reverseObjectEnumerator];
                    
                    for (UIWindow *window in frontToBackWindows)
                        if (window.windowLevel == UIWindowLevelNormal) {
                            destView = window;
                            break;
                        }
                }
                [destView addSubview:self];
                [destView bringSubviewToFront:self];
            }
            
            [self updateForInterfaceOrientation];
            
            self.hidden = NO;
            self.alpha = 1.0;
            
            _backgroundView.alpha = 0.0;
            _backgroundView.alpha = 0.0;
            void (^backgroundAnimationBlock)(void) = ^(void) {
                _backgroundView.alpha = 1.0;
            };
            
            switch (_maskType) {
                case DLPopupContainerMaskTypeDimmed: {
                    _backgroundView.backgroundColor = [UIColor colorWithRed:(CGFloat) (0.0 / 255.0f) green:(CGFloat) (0.0 / 255.0f) blue:(CGFloat) (0.0 / 255.0f) alpha:self.dimmedMaskAlpha];
                    backgroundAnimationBlock();
                    
                }
                    break;
                case DLPopupContainerMaskTypeNone: {
                    [UIView animateWithDuration:0.15
                                          delay:0
                                        options:UIViewAnimationOptionCurveLinear
                                     animations:backgroundAnimationBlock
                                     completion:NULL];
                    
                }
                    break;
                case DLPopupContainerMaskTypeClear: {
                    _backgroundView.backgroundColor = [UIColor clearColor];
                }
                    break;
                case DLPopupContainerMaskTypeLightBlur: {
                    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                    UIVisualEffectView *visualBlur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                    visualBlur.frame = _backgroundView.frame;
                    [visualBlur.contentView addSubview:_backgroundView];
                    [self insertSubview:visualBlur belowSubview:_containerView];
                    //_backgroundView = visualBlur;
                    //[self addSubview:visualBlur];
                }
                    break;
                case DLPopupContainerMaskTypeDarkBlur: {
                    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                    UIVisualEffectView *visualBlur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                    visualBlur.frame = _backgroundView.frame;
                    [visualBlur.contentView addSubview:_backgroundView];
                    [self insertSubview:visualBlur belowSubview:_containerView];
                    //_backgroundView = visualBlur;
                    //[self addSubview:visualBlur];
                }
                    break;
                    
                default:
                    backgroundAnimationBlock();
                    break;
            }
            
            NSTimeInterval duration;
            NSNumber *durationNumber = [parameters valueForKey:@"duration"];
            if (durationNumber != nil) {
                duration = durationNumber.doubleValue;
            } else {
                duration = 0.0;
            }
            
            void (^completionBlock)(BOOL) = ^(BOOL finished) {
                _isBeingShown = NO;
                _isShowing = YES;
                _isBeingDismissed = NO;
                
                [self didFinishShowing];
                
                if (self.didFinishShowingCompletion != nil) {
                    self.didFinishShowingCompletion();
                }
                
                if (duration > 0.0) {
                    [self performSelector:@selector(dismiss) withObject:nil afterDelay:duration];
                }
            };
            
            if (self.contentView.superview != _containerView) {
                [_containerView addSubview:self.contentView];
            }
            
            [self.contentView layoutIfNeeded];
            
            CGRect containerFrame = _containerView.frame;
            containerFrame.size = self.contentView.frame.size;
            _containerView.frame = containerFrame;

            CGRect contentViewFrame = self.contentView.frame;
            contentViewFrame.origin = CGPointZero;
            self.contentView.frame = contentViewFrame;
            
            UIView *contentView = _contentView;
            NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
            
            [_containerView removeConstraints:_containerView.constraints];
            [_containerView addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|"
                                                     options:0
                                                     metrics:nil
                                                       views:views]];
            
            [_containerView addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                     options:0
                                                     metrics:nil
                                                       views:views]];
            
            CGRect finalContainerFrame = containerFrame;
            UIViewAutoresizing containerAutoresizingMask = UIViewAutoresizingNone;
            
            NSValue *centerValue = [parameters valueForKey:@"center"];
            if (centerValue != nil) {
                
                CGPoint centerInView = [centerValue CGPointValue];
                CGPoint centerInSelf;
                
                if (destView != nil) {
                    centerInSelf = [self convertPoint:centerInView fromView:destView];
                } else {
                    centerInSelf = centerInView;
                }
                
                finalContainerFrame.origin.x = (CGFloat) (centerInSelf.x - CGRectGetWidth(finalContainerFrame) / 2.0);
                finalContainerFrame.origin.y = (CGFloat) (centerInSelf.y - CGRectGetHeight(finalContainerFrame) / 2.0);
                containerAutoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
            } else {
                
                NSValue *layoutValue = [parameters valueForKey:@"layout"];
                DLPopupContainerLayout layout;
                if (layoutValue != nil) {
                    layout = [layoutValue DLPopupContainerLayoutValue];
                } else {
                    layout = DLPopupContainerLayoutCenter;
                }
                
                switch (layout.horizontal) {
                        
                    case DLPopupContainerHorizontalLayoutLeft: {
                        finalContainerFrame.origin.x = 0.0;
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case DLPopupContainerHorizontalLayoutLeftOfCenter: {
                        finalContainerFrame.origin.x = floorf((float) (CGRectGetWidth(self.bounds) / 3.0 - CGRectGetWidth(containerFrame) / 2.0));
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case DLPopupContainerHorizontalLayoutCenter: {
                        finalContainerFrame.origin.x = floorf((float) ((CGRectGetWidth(self.bounds) - CGRectGetWidth(containerFrame)) / 2.0));
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case DLPopupContainerHorizontalLayoutRightOfCenter: {
                        finalContainerFrame.origin.x = floorf((float) (CGRectGetWidth(self.bounds) * 2.0 / 3.0 - CGRectGetWidth(containerFrame) / 2.0));
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case DLPopupContainerHorizontalLayoutRight: {
                        finalContainerFrame.origin.x = CGRectGetWidth(self.bounds) - CGRectGetWidth(containerFrame);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin;
                        break;
                    }
                        
                    default:
                        break;
                }
                
                // Vertical
                switch (layout.vertical) {
                        
                    case DLPopupContainerVerticalLayoutTop: {
                        finalContainerFrame.origin.y = 0;
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case DLPopupContainerVerticalLayoutAboveCenter: {
                        finalContainerFrame.origin.y = floorf((float) CGRectGetHeight(self.bounds) / 3.0 - CGRectGetHeight(containerFrame) / 2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case DLPopupContainerVerticalLayoutCenter: {
                        finalContainerFrame.origin.y = floorf((float) (CGRectGetHeight(self.bounds) - CGRectGetHeight(containerFrame)) / 2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case DLPopupContainerVerticalLayoutBelowCenter: {
                        finalContainerFrame.origin.y = floorf((float) CGRectGetHeight(self.bounds) * 2.0 / 3.0 - CGRectGetHeight(containerFrame) / 2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case DLPopupContainerVerticalLayoutBottom: {
                        finalContainerFrame.origin.y = CGRectGetHeight(self.bounds) - CGRectGetHeight(containerFrame);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin;
                        break;
                    }
                        
                    default:
                        break;
                }
            }
            
            _containerView.autoresizingMask = containerAutoresizingMask;
            
            switch (_showType) {
                case DLPopupContainerShowTypeFadeIn: {
                    
                    _containerView.alpha = 0.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.15
                                          delay:0
                                        options:UIViewAnimationOptionCurveLinear
                                     animations:^{
                                         _containerView.alpha = 1.0;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeGrowIn: {
                    
                    _containerView.alpha = 0.0;
                    
                    CGRect startFrame = finalContainerFrame;
                    _containerView.frame = startFrame;
                    _containerView.transform = CGAffineTransformMakeScale(0.85, 0.85);
                    
                    [UIView animateWithDuration:0.15
                                          delay:0
                                        options:kAnimationOptionCurveIOS7
                                     animations:^{
                                         _containerView.alpha = 1.0;
                                         
                                         _containerView.transform = CGAffineTransformIdentity;
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    
                    break;
                }
                    
                case DLPopupContainerShowTypeShrinkIn: {
                    _containerView.alpha = 0.0;
                    
                    CGRect startFrame = finalContainerFrame;
                    _containerView.frame = startFrame;
                    _containerView.transform = CGAffineTransformMakeScale(1.25, 1.25);
                    
                    [UIView animateWithDuration:0.15
                                          delay:0
                                        options:kAnimationOptionCurveIOS7
                                     animations:^{
                                         _containerView.alpha = 1.0;
                                         
                                         _containerView.transform = CGAffineTransformIdentity;
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeSlideInFromTop: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = -CGRectGetHeight(finalContainerFrame);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeSlideInFromBottom: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = CGRectGetHeight(self.bounds);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeSlideInFromLeft: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = -CGRectGetWidth(finalContainerFrame);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeSlideInFromRight: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = CGRectGetWidth(self.bounds);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    
                    break;
                }
                    
                case DLPopupContainerShowTypeBounceIn: {
                    _containerView.alpha = 0.0;
                    
                    CGRect startFrame = finalContainerFrame;
                    _containerView.frame = startFrame;
                    _containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:15.0
                                        options:0
                                     animations:^{
                                         _containerView.alpha = 1.0;
                                         _containerView.transform = CGAffineTransformIdentity;
                                     }
                                     completion:completionBlock];
                    
                    break;
                }
                    
                case DLPopupContainerShowTypeBounceInFromTop: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = -CGRectGetHeight(finalContainerFrame);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeBounceInFromBottom: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = CGRectGetHeight(self.bounds);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeBounceInFromLeft: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = -CGRectGetWidth(finalContainerFrame);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case DLPopupContainerShowTypeBounceInFromRight: {
                    _containerView.alpha = 1.0;
                    _containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = CGRectGetWidth(self.bounds);
                    _containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         _containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                default: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    self.containerView.frame = finalContainerFrame;
                    
                    completionBlock(YES);
                    
                    break;
                }
            }
            
        });
    }
}


- (void)dismiss
{
    [self dismiss:YES];
}


- (void)updateForInterfaceOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat angle;
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI / 2.0f;;
            
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI / 2.0f;
            
            break;
        default: // UIInterfaceOrientationPortrait
            angle = 0.0;
            break;
    }
    
    self.transform = CGAffineTransformMakeRotation(angle);
    self.frame = self.window.bounds;

}


#pragma mark - Notification handlers

- (void)didChangeStatusBarOrientation:(NSNotification *)notification
{
    [self updateForInterfaceOrientation];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGRect keyboardRect;
    [[[notification userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    _keyboardRect = [self convertRect:keyboardRect fromView:nil];
    
}

- (void)keyboardDidHide:(NSNotification *)notification {
    _keyboardRect = CGRectZero;
}


#pragma mark - Subclassing

- (void)willStartShowing
{
    if (_shouldHandleKeyboard) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    }
}


- (void)didFinishShowing
{
    
}


- (void)willStartDismissing
{
    
}


- (void)didFinishDismissing
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Keyboard notification handlers

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    [self moveContainerViewForKeyboard:notification up:YES];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    [self moveContainerViewForKeyboard:notification up:NO];
}

- (void)moveContainerViewForKeyboard:(NSNotification *)notification up:(BOOL)up
{
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve animationCurve = (UIViewAnimationCurve) [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    _containerView.center = CGPointMake(_containerView.superview.frame.size.width / 2, _containerView.superview.frame.size.height / 2);
    CGRect frame = _containerView.frame;
    if (up) {
        frame.origin.y -= keyboardEndFrame.size.height / 2;
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    _containerView.frame = frame;
    [UIView commitAnimations];
}

@end

#pragma mark - Categories

@implementation UIView (DLPopupContainer)


- (void)forEachPopupDoBlock:(void (^)(DLPopupContainer *popup))block
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[DLPopupContainer class]]) {
            block((DLPopupContainer *) subview);
        } else {
            [subview forEachPopupDoBlock:block];
        }
    }
}


- (void)dismissPresentingPopup
{
    UIView *view = self;
    while (view != nil) {
        if ([view isKindOfClass:[DLPopupContainer class]]) {
            [(DLPopupContainer *) view dismiss:YES];
            break;
        }
        view = view.superview;
    }
}

@end


@implementation NSValue (DLPopupContainerLayout)

+ (NSValue *)valueWithPopupContainerLayout:(DLPopupContainerLayout)layout
{
    return [NSValue valueWithBytes:&layout objCType:@encode(DLPopupContainerLayout)];
}

- (DLPopupContainerLayout)DLPopupContainerLayoutValue
{
    DLPopupContainerLayout layout;
    
    [self getValue:&layout];
    
    return layout;
}

@end

