//
//  FaceScene.h
//  SpriteKitWatchFace
//
//  Created by Steven Troughton-Smith on 10/10/2018.
//  Copyright © 2018 Steven Troughton-Smith. All rights reserved.
//

//
//  Redesigned by Nazar Tkachenko on 11/11/2018
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
/* Hermes */
	ThemeHermesDuoPink,
	ThemeHermesDuoOrange,
    ThemeHermesSolidPink,
    ThemeHermesSolidOrange,
    ThemeHermesSolidGold,
    ThemeHermesSolidWhite,

/* Nike Sport */
    ThemeNikeBlue,
    ThemeNikeBlueBlack,
    ThemeNikeOrange,
    ThemeNikeOrangeBlack,
    ThemeNikeRed,
    ThemeNikeRedBlack,
    ThemeNikeNeon,
    ThemeNikeNeonBlack,
    ThemeNikePink,
    ThemeNikePinkBlack,
    ThemeNikeSky,
    ThemeNikeSkyBlack,
    ThemeNikeNavy,
    ThemeNikeNavyBlack,
    ThemeNikeWhite,
    ThemeNikeBlack,
    
/* Solid Rectangle */
	ThemeNavy,
    ThemeContrast,
    ThemeLiquid,
	ThemeNoir,
    ThemeVictoire,
	ThemeAngler,
	ThemeDelay,
	ThemeLuxe,
	ThemeSage,
	ThemeBondi,
	ThemeTangerine,
	ThemeStrawberry,
	ThemePawn,
	ThemeRoyal,
	ThemeMarques,
    
	ThemeMAX,
} Theme;

typedef enum : NSUInteger {
	NumeralStyleAll,
	NumeralStyleCardinal,
    NumeralStyleNike,
    NumeralStyleHermesDuo,
    NumeralStyleHermesSolid,
	NumeralStyleNone,
	NumeralStyleMAX
} NumeralStyle;

typedef enum : NSUInteger {
	TickmarkStyleAll,
	TickmarkStyleMajor,
	TickmarkStyleMinor,
	TickmarkStyleStackMajor,
	TickmarkStyleNone,
	TickmarkStyleMAX
} TickmarkStyle;

typedef enum : NSUInteger {
	FaceStyleRound,
	FaceStyleRectangular,
	FaceStyleMAX
} FaceStyle;

typedef enum : NSUInteger {
	ColorRegionStyleNone,
	ColorRegionStyleDynamicDuo,
	ColorRegionStyleHalf,
	ColorRegionStyleCircle,
	ColorRegionStyleRing,
	ColorRegionStyleMAX
} ColorRegionStyle;

typedef enum : NSUInteger {
	TickmarkShapeRectangular,
	TickmarkShapeCircular,
	TickmarkShapeTriangular,
	TickmarkShapeMAX
} TickmarkShape;

typedef enum : NSUInteger {
	DateStyleNone,
	DateStyleDay,
	DateStyleDate,
	DateStyleDayDate,
    DateStyleHermesDuo,
    DateStyleHermesSolid,
	DateStyleMAX
} DateStyle;

typedef enum : NSUInteger {
	DateQuadrantRight,
	DateQuadrantBottom,
	DateQuadrantLeft,
	DateQuadrantTop,
    DateQuadrantHermes,
	DateQuadrantMAX
} DateQuadrant;

typedef enum : NSUInteger {
	CenterDiscStyleNone,
	CenterDiscStyleEnabled,
	CenterDiscStyleMAX
} CenterDiscStyle;

typedef enum : NSUInteger {
    MonogramStyleRegular,
    MonogramStyleNike,
    MonogramStyleMAX
} MonogramStyle;

@interface FaceScene : SKScene <SKSceneDelegate>

-(void)refreshTheme;

@property Theme theme;
@property NumeralStyle numeralStyle;
@property TickmarkStyle tickmarkStyle;
@property TickmarkShape majorTickmarkShape;
@property TickmarkShape minorTickmarkShape;
@property FaceStyle faceStyle;
@property ColorRegionStyle colorRegionStyle;
@property DateStyle dateStyle;
@property DateQuadrant dateQuadrant;
@property CenterDiscStyle centerDiscStyle;
@property MonogramStyle monogramStyle;

@property SKColor *colorRegionColor;
@property SKColor *faceBackgroundColor;
@property SKColor *handColor;
@property SKColor *secondHandColor;
@property SKColor *inlayColor;
@property SKColor *dotColor;

@property SKColor *majorMarkColor;
@property SKColor *minorMarkColor;
@property SKColor *textColor;

@property SKColor *dateColor;

@property SKColor *alternateMajorMarkColor;
@property SKColor *alternateMinorMarkColor;
@property SKColor *alternateTextColor;

@property SKColor *monogramColor;
@property NSString *monogram;

@property BOOL useBackgroundImageOverlay;
@property BOOL useMasking;

@property BOOL showLogo;

@property CGSize faceSize;

@property CGFloat majorTickHeight;
@property CGFloat majorTickWidth;
@property CGFloat minorTickHeight;

@end

NS_ASSUME_NONNULL_END
