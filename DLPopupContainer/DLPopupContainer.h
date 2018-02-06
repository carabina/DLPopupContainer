//
//  DLPopupContainer.h
//  PopupContainer
//
//  Created by Dalang on 2018/2/5.
//  Copyright © 2018年 Dalang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
// DLPopupContainerShowType
typedef NS_ENUM(NSInteger, DLPopupContainerShowType) {
    DLPopupContainerShowTypeNone = 0,
    DLPopupContainerShowTypeFadeIn,
    DLPopupContainerShowTypeGrowIn,
    DLPopupContainerShowTypeShrinkIn,
    DLPopupContainerShowTypeSlideInFromTop,
    DLPopupContainerShowTypeSlideInFromBottom,
    DLPopupContainerShowTypeSlideInFromLeft,
    DLPopupContainerShowTypeSlideInFromRight,
    DLPopupContainerShowTypeBounceIn,
    DLPopupContainerShowTypeBounceInFromTop,
    DLPopupContainerShowTypeBounceInFromBottom,
    DLPopupContainerShowTypeBounceInFromLeft,
    DLPopupContainerShowTypeBounceInFromRight,
};

// DLPopupContainerDismissType
typedef NS_ENUM(NSInteger, DLPopupContainerDismissType) {
    DLPopupContainerDismissTypeNone = 0,
    DLPopupContainerDismissTypeFadeOut,
    DLPopupContainerDismissTypeGrowOut,
    DLPopupContainerDismissTypeShrinkOut,
    DLPopupContainerDismissTypeSlideOutToTop,
    DLPopupContainerDismissTypeSlideOutToBottom,
    DLPopupContainerDismissTypeSlideOutToLeft,
    DLPopupContainerDismissTypeSlideOutToRight,
    DLPopupContainerDismissTypeBounceOut,
    DLPopupContainerDismissTypeBounceOutToTop,
    DLPopupContainerDismissTypeBounceOutToBottom,
    DLPopupContainerDismissTypeBounceOutToLeft,
    DLPopupContainerDismissTypeBounceOutToRight,
};


// DLPopupContainerHorizontalLayout
typedef NS_ENUM(NSInteger, DLPopupContainerHorizontalLayout) {
    DLPopupContainerHorizontalLayoutCustom = 0,
    DLPopupContainerHorizontalLayoutLeft,
    DLPopupContainerHorizontalLayoutLeftOfCenter,
    DLPopupContainerHorizontalLayoutCenter,
    DLPopupContainerHorizontalLayoutRightOfCenter,
    DLPopupContainerHorizontalLayoutRight,
};

// DLPopupContainerVerticalLayout
typedef NS_ENUM(NSInteger, DLPopupContainerVerticalLayout) {
    DLPopupContainerVerticalLayoutCustom = 0,
    DLPopupContainerVerticalLayoutTop,
    DLPopupContainerVerticalLayoutAboveCenter,
    DLPopupContainerVerticalLayoutCenter,
    DLPopupContainerVerticalLayoutBelowCenter,
    DLPopupContainerVerticalLayoutBottom,
};

// DLPopupContainerMaskType
typedef NS_ENUM(NSInteger, DLPopupContainerMaskType) {
    DLPopupContainerMaskTypeNone = 0,
    DLPopupContainerMaskTypeClear,
    DLPopupContainerMaskTypeDimmed,
    DLPopupContainerMaskTypeLightBlur,
    DLPopupContainerMaskTypeDarkBlur,
};

// DLPopupContainerLayout
typedef struct {
    DLPopupContainerHorizontalLayout horizontal;
    DLPopupContainerVerticalLayout vertical;
} DLPopupContainerLayout;

DLPopupContainerLayout DLPopupContainerLayoutMake(DLPopupContainerHorizontalLayout horizontal, DLPopupContainerVerticalLayout vertical);

static const DLPopupContainerLayout DLPopupContainerLayoutCenter;

@interface DLPopupContainer : UIView

/**
 将要显示的 PopupView
 */
@property(nonatomic, strong) UIView *contentView;

/**
 显示动画类型 默认 DLPopupContainerShowTypeShrinkIn
 */
@property(nonatomic, assign) DLPopupContainerShowType showType;

/**
 隐藏动画类型 默认 DLPopupContainerDismissTypeShrinkOut
 */
@property(nonatomic, assign) DLPopupContainerDismissType dismissType;

/**
 背景类型 默认 DLPopupContainerMaskTypeDimmed
 */
@property(nonatomic, assign) DLPopupContainerMaskType maskType;

/**
 背景类型为DLPopupContainerMaskTypeDimmed时的的透明度 默认 0.5
 */
@property(nonatomic, assign) CGFloat dimmedMaskAlpha;

/**
 点击背景是否消失，默认 YES
 */
@property(nonatomic, assign) BOOL shouldDismissOnBackgroundTouch;

/**
 点击 ContentView 是否消失 默认 NO
 */
@property(nonatomic, assign) BOOL shouldDismissOnContentTouch;

/**
 是否随键盘升降 默认 NO
 */
@property(nonatomic, assign) BOOL shouldHandleKeyboard;

/**
 显示完成的block
 */
@property(nonatomic, copy) void (^didFinishShowingCompletion)(void);

/**
 开始消失时的block
 */
@property(nonatomic, copy) void (^willStartDismissingCompletion)(void);

/**
 消失完成的block
 */
@property(nonatomic, copy) void (^didFinishDismissingCompletion)(void);

/**
 初始化

 @param contentView 要显示的View
 @return DLPopupContainer
 */
+ (instancetype)popupContainerWithContentView:(UIView *)contentView;

/**
 初始化

 @param contentView 要显示的View
 @param showType 显示动画类型
 @param dismissType 消失动画类型
 @param maskType 背景类型
 @param shouldDismissOnBackgroundTouch 点击背景是否小时
 @param shouldDismissOnContentTouch 点击contentView是否小时
 @return DLPopupContainer
 */
+ (instancetype)popupContainerWithContentView:(UIView *)contentView
                                     showType:(DLPopupContainerShowType)showType
                                  dismissType:(DLPopupContainerDismissType)dismissType
                                     maskType:(DLPopupContainerMaskType)maskType
               shouldDismissOnBackgroundTouch:(BOOL)shouldDismissOnBackgroundTouch
                  shouldDismissOnContentTouch:(BOOL)shouldDismissOnContentTouch;

/**
 隐藏所有 DLPopupContainer
 */
+ (void)dismissAllPopups;

/**
 Show
 */
- (void)show;

/**
 以特定布局显示

 @param layout 布局
 */
- (void)showWithLayout:(DLPopupContainerLayout)layout;

/**
 以特定布局类型显示特定View

 @param layout 布局类型
 @param view View
 */
- (void)showWithLayout:(DLPopupContainerLayout)layout
                inView:(UIView*) view;

/**
 显示特定时间后消失

 @param duration 时间
 */
- (void)showWithDuration:(NSTimeInterval)duration;

/**
 以特定布局消失特定时间后消失

 @param layout 布局
 @param duration 时间
 */
- (void)showWithLayout:(DLPopupContainerLayout)layout duration:(NSTimeInterval)duration;

/**
 在特定位置显示View

 @param center 特定位置
 @param view view
 */
- (void)showAtCenter:(CGPoint)center inView:(UIView *)view;


/**
 在特定位置使特定View显示特定时间后消失

 @param center 位置
 @param view View
 @param duration 时间
 */
- (void)showAtCenter:(CGPoint)center inView:(UIView *)view withDuration:(NSTimeInterval)duration;

/**
 消失

 @param animated 是否有消失动画
 */
- (void)dismiss:(BOOL)animated;


#pragma mark Subclassing

@property(nonatomic, strong, readonly) UIView *backgroundView;
@property(nonatomic, strong, readonly) UIView *containerView;
@property(nonatomic, assign, readonly) BOOL isBeingShown;
@property(nonatomic, assign, readonly) BOOL isShowing;
@property(nonatomic, assign, readonly) BOOL isBeingDismissed;

- (void)willStartShowing;

- (void)didFinishShowing;

- (void)willStartDismissing;

- (void)didFinishDismissing;

@end

#pragma mark - UIView Category

@interface UIView (DLPopupContainer)
- (void)forEachPopupDoBlock:(void (^)(DLPopupContainer *popup))block NS_SWIFT_NAME(UIView.forEachPopup(handle:));

- (void)dismissPresentingPopup;
@end

NS_ASSUME_NONNULL_END
