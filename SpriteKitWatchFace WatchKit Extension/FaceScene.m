//
//  FaceScene.m
//  SpriteKitWatchFace
//
//  Created by Steven Troughton-Smith on 10/10/2018.
//  Copyright © 2018 Steven Troughton-Smith. All rights reserved.
//

//
//  Redesigned by Nazar Tkachenko on 11/11/2018
//

#import "FaceScene.h"

@import CoreText;

#if TARGET_OS_IPHONE

/* Sigh. */

#define NSFont UIFont
#define NSFontWeightMedium UIFontWeightMedium

#define NSFontFeatureTypeIdentifierKey UIFontFeatureTypeIdentifierKey
#define NSFontFeatureSettingsAttribute UIFontDescriptorFeatureSettingsAttribute
#define NSFontDescriptor UIFontDescriptor

#define NSFontFeatureSelectorIdentifierKey UIFontFeatureSelectorIdentifierKey
#define NSFontNameAttribute UIFontDescriptorNameAttribute

#endif

#define PREPARE_SCREENSHOT 0 // Change to 1 for static time positioning (good for screenshots), keep 0 for practical use

CGFloat workingRadiusForFaceOfSizeWithAngle(CGSize faceSize, CGFloat angle)
{
	CGFloat faceHeight = faceSize.height;
	CGFloat faceWidth = faceSize.width;
	
	CGFloat workingRadius = 0;
	
	double vx = cos(angle);
	double vy = sin(angle);
	
	double x1 = 0;
	double y1 = 0;
	double x2 = faceHeight;
	double y2 = faceWidth;
	double px = faceHeight/2;
	double py = faceWidth/2;
	
	double t[4];
	double smallestT = 1000;
	
	t[0]=(x1-px)/vx;
	t[1]=(x2-px)/vx;
	t[2]=(y1-py)/vy;
	t[3]=(y2-py)/vy;
	
	for (int m = 0; m < 4; m++)
	{
		double currentT = t[m];
		
		if (currentT > 0 && currentT < smallestT)
			smallestT = currentT;
	}
	
	workingRadius = smallestT;
	
	return workingRadius;
}

@implementation NSFont (SmallCaps)
-(NSFont *)smallCaps
{
	NSArray *settings = @[@{NSFontFeatureTypeIdentifierKey: @(kUpperCaseType), NSFontFeatureSelectorIdentifierKey: @(kUpperCaseSmallCapsSelector)}];
	NSDictionary *attributes = @{NSFontFeatureSettingsAttribute: settings, NSFontNameAttribute: self.fontName};
	
	return [NSFont fontWithDescriptor:[NSFontDescriptor fontDescriptorWithFontAttributes:attributes] size:self.pointSize];
}
@end

@implementation FaceScene

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		
		self.faceSize = (CGSize){184, 224};

		self.theme = [[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeHermesDuoPink"];
		self.useBackgroundImageOverlay = NO;
		self.faceStyle = FaceStyleRectangular;
        self.numeralStyle = NumeralStyleAll;
		self.tickmarkStyle = TickmarkStyleNone;
		self.majorTickmarkShape = TickmarkShapeRectangular;
		self.minorTickmarkShape = TickmarkShapeRectangular;
		
		self.majorTickHeight = 6;
		self.majorTickWidth = 2;

		self.colorRegionStyle = ColorRegionStyleDynamicDuo;
		
		self.dateStyle = DateStyleDayDate;
		self.dateQuadrant = DateQuadrantRight;

        self.monogramStyle = MonogramStyleRegular;
		self.monogram = @""; // e.g. 
		
		[self refreshTheme];
		
        // Ignore the warnings that come up here, they're not errors
        NSLog(@"Permutations per theme = %lu", FaceStyleMAX*NumeralStyleMAX*TickmarkStyleMAX*(TickmarkShapeMAX*2)*ColorRegionStyleMAX*DateStyleMAX*CenterDiscStyleMAX*DateQuadrantMAX*MonogramStyleMAX);
        NSLog(@"Total permutations = %lu", ThemeMAX*FaceStyleMAX*NumeralStyleMAX*TickmarkStyleMAX*(TickmarkShapeMAX*2)*ColorRegionStyleMAX*DateStyleMAX*CenterDiscStyleMAX*DateQuadrantMAX*MonogramStyleMAX);
		
		self.delegate = self;
	}
	return self;
}

#pragma mark -

-(void)setupTickmarksForRoundFaceWithLayerName:(NSString *)layerName
{
	CGFloat margin = 4.0;
	CGFloat labelMargin = 26.0;
	
	SKCropNode *faceMarkings = [SKCropNode node];
	faceMarkings.name = layerName;
	
	/* Hardcoded for 44mm Apple Watch */
	
	CGFloat shortTickHeight = 0;
	
	/* Minor */
	for (int i = 0; i < 60; i++)
	{
		CGFloat angle = - (2*M_PI)/60.0 * i;
		CGFloat workingRadius = self.faceSize.width/2;
		shortTickHeight = workingRadius/20;
		if (self.minorTickHeight > 0)
			shortTickHeight = self.minorTickHeight;
		
		SKSpriteNode *tick = [SKSpriteNode spriteNodeWithColor:self.minorMarkColor size:CGSizeMake(1, shortTickHeight)];
		
		tick.position = CGPointZero;
		tick.anchorPoint = CGPointMake(0.5, (workingRadius-margin)/shortTickHeight);
		tick.zRotation = angle;
		
		if (self.tickmarkStyle == TickmarkStyleAll || self.tickmarkStyle == TickmarkStyleMinor || self.tickmarkStyle == TickmarkStyleStackMajor)
		{
			if ((self.tickmarkStyle == TickmarkStyleStackMajor) || (self.tickmarkStyle == TickmarkStyleMinor) || i % 5 != 0)
			{
				[faceMarkings addChild:tick];
				
				if (self.minorTickmarkShape == TickmarkShapeCircular)
				{
					tick.color = [SKColor clearColor];
					
					SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithEllipseOfSize:CGSizeMake(3, 3)];
					shapeNode.fillColor = self.minorMarkColor;
					shapeNode.strokeColor = [SKColor clearColor];
					shapeNode.position = CGPointMake(0, (workingRadius-margin)-shortTickHeight/2);
					[tick addChild:shapeNode];
				}
				else if (self.minorTickmarkShape == TickmarkShapeTriangular)
				{
					tick.color = [SKColor clearColor];
					
					CGFloat triangleHeight = 2;
					CGFloat triangleWidth = 2;
					
					if (self.numeralStyle == NumeralStyleNone)
						triangleHeight = 4;
					
					CGPoint tp[3] = {CGPointMake(-(0.5 * triangleWidth), triangleHeight), CGPointMake(0, -triangleHeight), CGPointMake((0.5 * triangleWidth), triangleHeight)};
					
					SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPoints:tp count:3];
					shapeNode.fillColor = self.minorMarkColor;
					shapeNode.strokeColor = [SKColor clearColor];
					shapeNode.position = CGPointMake(0, (workingRadius-margin)-triangleHeight);
					[tick addChild:shapeNode];
				}
			}
		}
	}
	
	/* Major */
	for (int i = 0; i < 12; i++)
	{
		CGFloat angle = -(2*M_PI)/12.0 * i;
		CGFloat workingRadius = self.faceSize.width/2;
		CGFloat longTickHeight = workingRadius/15;
		if (self.majorTickHeight > 0)
			longTickHeight = self.majorTickHeight;
		
		SKSpriteNode *tick = [SKSpriteNode spriteNodeWithColor:self.majorMarkColor size:CGSizeMake(self.majorTickWidth, longTickHeight)];
		
		if (self.tickmarkStyle == TickmarkStyleStackMajor)
		{
			workingRadius -= shortTickHeight + 2;
		}
		
		tick.position = CGPointZero;
		tick.anchorPoint = CGPointMake(0.5, (workingRadius-margin)/longTickHeight);
		tick.zRotation = angle;
		
		
		
		if (self.tickmarkStyle == TickmarkStyleAll || self.tickmarkStyle == TickmarkStyleMajor || self.tickmarkStyle == TickmarkStyleStackMajor)
		{
			[faceMarkings addChild:tick];
			
			if (self.majorTickmarkShape == TickmarkShapeCircular)
			{
				tick.color = [SKColor clearColor];
				
				SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithEllipseOfSize:CGSizeMake(longTickHeight, longTickHeight)];
				shapeNode.fillColor = self.majorMarkColor;
				shapeNode.strokeColor = [SKColor clearColor];
				shapeNode.position = CGPointMake(0, (workingRadius-margin)-longTickHeight/2);
				[tick addChild:shapeNode];
			}
			else if (self.majorTickmarkShape == TickmarkShapeTriangular)
			{
				tick.color = [SKColor clearColor];
				
				CGFloat triangleHeight = 3;
				CGFloat triangleWidth = 4;

				if (self.numeralStyle == NumeralStyleNone)
					triangleHeight = 8;
				
				CGPoint tp[3] = {CGPointMake(-(0.5 * triangleWidth), triangleHeight), CGPointMake(0, -triangleHeight), CGPointMake((0.5 * triangleWidth), triangleHeight)};
				
				SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPoints:tp count:3];
                shapeNode.fillColor = self.majorMarkColor;
				shapeNode.strokeColor = [SKColor clearColor];
				shapeNode.position = CGPointMake(0, (workingRadius-margin)-triangleHeight);
				[tick addChild:shapeNode];
			}
			
		}
		
		CGFloat h = 25;
		
		NSDictionary *attribs = @{NSFontAttributeName : [NSFont systemFontOfSize:h weight:NSFontWeightMedium], NSForegroundColorAttributeName : self.textColor};
		
		NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i", i == 0 ? 12 : i] attributes:attribs];
		
		SKLabelNode *numberLabel = [SKLabelNode labelNodeWithAttributedText:labelText];
		numberLabel.position = CGPointMake((workingRadius-labelMargin) * -sin(angle), (workingRadius-labelMargin) * cos(angle) - 9);
		
		
		if (self.numeralStyle == NumeralStyleAll || ((self.numeralStyle == NumeralStyleCardinal) && (i % 3 == 0)))
			[faceMarkings addChild:numberLabel];
	}
	
	
	
	if (self.dateStyle != DateStyleNone)
	{
		NSDateFormatter * df = [[NSDateFormatter alloc] init];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]]];
		
		if (self.dateStyle == DateStyleDay)
		{
			[df setDateFormat:@"ccc"];
		}
		else if (self.dateStyle == DateStyleDate)
		{
			[df setDateFormat:@"d"];
		}
		else if (self.dateStyle == DateStyleDayDate)
		{
			[df setDateFormat:@"ccc d"];
		}
		
		CGFloat h = 12;
		CGFloat numeralDelta = 0.0;
		
        NSDictionary *attribs = @{NSFontAttributeName : [[NSFont systemFontOfSize:h weight:NSFontWeightMedium] smallCaps], NSForegroundColorAttributeName : self.dateColor};
		
		NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:[[df stringFromDate:[NSDate date]] uppercaseString] attributes:attribs];
		
		SKLabelNode *numberLabel = [SKLabelNode labelNodeWithAttributedText:labelText];
		numberLabel.name = @"Date";

		if (self.numeralStyle == NumeralStyleNone)
			numeralDelta = 10.0;
		
		if (self.dateQuadrant == DateQuadrantRight)
			numberLabel.position = CGPointMake(32+numeralDelta, -4);
		else if (self.dateQuadrant == DateQuadrantLeft)
			numberLabel.position = CGPointMake(-(32+numeralDelta), -4);
		else if (self.dateQuadrant == DateQuadrantTop)
			numberLabel.position = CGPointMake(0, (36+numeralDelta));
		else if (self.dateQuadrant == DateQuadrantBottom)
			numberLabel.position = CGPointMake(0, -(44+numeralDelta));
		
		[faceMarkings addChild:numberLabel];
	}
    
    if (self.monogram)
    {
        [faceMarkings addChild:[self setupMonogramWithFontSize:16 horizontalOffset:0 verticalOffset:24]];
    }

	[self addChild:faceMarkings];
}


-(void)setupTickmarksForRectangularFaceWithLayerName:(NSString *)layerName
{
	CGFloat margin = 5.0;
	CGFloat labelYMargin = 30.0;
	CGFloat labelXMargin = 24.0;
	
	SKCropNode *faceMarkings = [SKCropNode node];
	faceMarkings.name = layerName;

	/* Major */
	for (int i = 0; i < 12; i++)
	{
		CGFloat angle = -(2*M_PI)/12.0 * i;
		CGFloat workingRadius = workingRadiusForFaceOfSizeWithAngle(self.faceSize, angle);
		CGFloat longTickHeight = workingRadius/10.0;
		
		if (self.majorTickHeight > 0)
			longTickHeight = self.majorTickHeight;
		
		SKSpriteNode *tick = [SKSpriteNode spriteNodeWithColor:self.majorMarkColor size:CGSizeMake(self.majorTickWidth, longTickHeight)];
		
		if (self.tickmarkStyle == TickmarkStyleStackMajor)
		{
			workingRadius -= longTickHeight;
		}
		
		tick.position = CGPointZero;
		tick.anchorPoint = CGPointMake(0.5, (workingRadius-margin)/longTickHeight);
		tick.zRotation = angle;
		
		tick.zPosition = 0;
		
		if (self.tickmarkStyle == TickmarkStyleAll || self.tickmarkStyle == TickmarkStyleMajor || self.tickmarkStyle == TickmarkStyleStackMajor)
		{
			[faceMarkings addChild:tick];
		
			if (self.majorTickmarkShape == TickmarkShapeCircular)
			{
				CGFloat circleDiameter = 6;
				tick.color = [SKColor clearColor];
				
				SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithEllipseOfSize:CGSizeMake(circleDiameter, circleDiameter)];
				shapeNode.fillColor = self.majorMarkColor;
				shapeNode.strokeColor = [SKColor clearColor];
				shapeNode.position = CGPointMake(0, (workingRadius-margin)-circleDiameter/2);
				[tick addChild:shapeNode];
			}
			else if (self.majorTickmarkShape == TickmarkShapeTriangular)
			{
				tick.color = [SKColor clearColor];
				
				CGFloat triangleHeight = 3;
				CGFloat triangleWidth = 4;
				
				if (self.numeralStyle == NumeralStyleNone)
					triangleHeight = 8;
				
				CGPoint tp[3] = {CGPointMake(-(0.5 * triangleWidth), triangleHeight), CGPointMake(0, -triangleHeight), CGPointMake((0.5 * triangleWidth), triangleHeight)};
				
				SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPoints:tp count:3];
				shapeNode.fillColor = self.majorMarkColor;
				shapeNode.strokeColor = [SKColor clearColor];
				shapeNode.position = CGPointMake(0, (workingRadius-margin)-triangleHeight);
				[tick addChild:shapeNode];
			}
		}
	}
	
	/* Minor */
	for (int i = 0; i < 60; i++)
	{
		
		CGFloat angle =  (2*M_PI)/60.0 * i;
		CGFloat workingRadius = workingRadiusForFaceOfSizeWithAngle(self.faceSize, angle);
		CGFloat shortTickHeight = workingRadius/20;
		
		if (self.minorTickHeight > 0)
			shortTickHeight = self.minorTickHeight;
		
		SKSpriteNode *tick = [SKSpriteNode spriteNodeWithColor:self.minorMarkColor size:CGSizeMake(1, shortTickHeight)];
		
		/* Super hacky hack to inset the tickmarks at the four corners of a curved display instead of doing math */
		if (i == 6 || i == 7  || i == 23 || i == 24 || i == 36 || i == 37 || i == 53 || i == 54)
		{
			workingRadius -= 8;
		}

		tick.position = CGPointZero;
		tick.anchorPoint = CGPointMake(0.5, (workingRadius-margin)/shortTickHeight);
		tick.zRotation = angle;
		
		tick.zPosition = 0;
		
		if (self.tickmarkStyle == TickmarkStyleAll || self.tickmarkStyle == TickmarkStyleMinor || self.tickmarkStyle == TickmarkStyleStackMajor)
		{
			if ((self.tickmarkStyle == TickmarkStyleStackMajor) || (self.tickmarkStyle == TickmarkStyleMinor) || i % 5 != 0)
			{
				[faceMarkings addChild:tick];
				
				if (self.minorTickmarkShape == TickmarkShapeCircular)
				{
					tick.color = [SKColor clearColor];
					
					SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithEllipseOfSize:CGSizeMake(3, 3)];
					shapeNode.fillColor = self.minorMarkColor;
					shapeNode.strokeColor = [SKColor clearColor];
					shapeNode.position = CGPointMake(0, (workingRadius-margin)-shortTickHeight/2);
					[tick addChild:shapeNode];
				}
				else if (self.minorTickmarkShape == TickmarkShapeTriangular)
				{
					tick.color = [SKColor clearColor];
					
					CGFloat triangleHeight = 2;
					CGFloat triangleWidth = 2;
					
					if (self.numeralStyle == NumeralStyleNone)
						triangleHeight = 4;
					
					CGPoint tp[3] = {CGPointMake(-(0.5 * triangleWidth), triangleHeight), CGPointMake(0, -triangleHeight), CGPointMake((0.5 * triangleWidth), triangleHeight)};
					
					SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPoints:tp count:3];
					shapeNode.fillColor = self.minorMarkColor;
					shapeNode.strokeColor = [SKColor clearColor];
					shapeNode.position = CGPointMake(0, (workingRadius-margin)-triangleHeight);
					[tick addChild:shapeNode];
				}
			}
		}
	}
	
	/* Numerals */
	for (int i = 1; i <= 12; i++)
	{
		CGFloat fontSize = 25;
		
		SKSpriteNode *labelNode = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(fontSize, fontSize)];
		labelNode.anchorPoint = CGPointMake(0.5,0.5);
		
        if (self.numeralStyle == NumeralStyleAll || ((self.numeralStyle == NumeralStyleCardinal) && (i % 3 == 0)))
        {
            if (i == 1 || i == 11 || i == 12)
                labelNode.position = CGPointMake(labelXMargin-self.faceSize.width/2 + ((i+1)%3) * (self.faceSize.width-labelXMargin*2)/3.0 + (self.faceSize.width-labelXMargin*2)/6.0, self.faceSize.height/2-labelYMargin);
            else if (i == 5 || i == 6 || i == 7)
                labelNode.position = CGPointMake(labelXMargin-self.faceSize.width/2 + (2-((i+1)%3)) * (self.faceSize.width-labelXMargin*2)/3.0 + (self.faceSize.width-labelXMargin*2)/6.0, -self.faceSize.height/2+labelYMargin);
            else if (i == 2 || i == 3 || i == 4)
                labelNode.position = CGPointMake(self.faceSize.height/2-fontSize-labelXMargin, -(self.faceSize.width-labelXMargin*2)/2 + (2-((i+1)%3)) * (self.faceSize.width-labelXMargin*2)/3.0 + (self.faceSize.width-labelYMargin*2)/6.0);
            else if (i == 8 || i == 9 || i == 10)
                labelNode.position = CGPointMake(-self.faceSize.height/2+fontSize+labelXMargin, -(self.faceSize.width-labelXMargin*2)/2 + ((i+1)%3) * (self.faceSize.width-labelXMargin*2)/3.0 + (self.faceSize.width-labelYMargin*2)/6.0);
            
            [faceMarkings addChild:labelNode];
            
            NSDictionary *attribs = @{NSFontAttributeName : [NSFont fontWithName:@"Futura-Medium" size:fontSize], NSForegroundColorAttributeName : self.textColor};
            
            NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i", i] attributes:attribs];
            
            SKLabelNode *numberLabel = [SKLabelNode labelNodeWithAttributedText:labelText];
            
            numberLabel.position = CGPointMake(0, -9);
            
			[labelNode addChild:numberLabel];
        }
	}
	
	if (self.dateStyle != DateStyleNone && self.dateStyle != DateStyleHermesSolid) // Don't show the date for these styles, but for all others
	{
        // All of this is just for initial setup, don't even worry about it. The "updateDate" function is what you'll care about.
        
		NSDateFormatter * df = [[NSDateFormatter alloc] init];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]]];
		
		if (self.dateStyle == DateStyleDay) // Only show day of the week
		{
			[df setDateFormat:@"ccc"];
		}
        else if (self.dateStyle == DateStyleDate || self.dateStyle == DateStyleHermesDuo) // Only show date #
		{
			[df setDateFormat:@"d"];
		}
        else if (self.dateStyle == DateStyleDayDate) // Day of the week + date #
		{
			[df setDateFormat:@"ccc d"];
		}
		
		CGFloat h = 12;
		
        NSDictionary *attribs = @{NSFontAttributeName : [[NSFont systemFontOfSize:h weight:NSFontWeightMedium] smallCaps], NSForegroundColorAttributeName : self.dateColor};
		
		NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:[[df stringFromDate:[NSDate date]] uppercaseString] attributes:attribs];
		
		SKLabelNode *numberLabel = [SKLabelNode labelNodeWithAttributedText:labelText];
		numberLabel.name = @"Date";
		CGFloat numeralDelta = 0.0;
		
		if (self.numeralStyle == NumeralStyleNone)
			numeralDelta = 10.0;
		if (self.dateQuadrant == DateQuadrantRight)
			numberLabel.position = CGPointMake(32+numeralDelta, -4);
		else if (self.dateQuadrant == DateQuadrantLeft)
			numberLabel.position = CGPointMake(-(32+numeralDelta), -4);
		else if (self.dateQuadrant == DateQuadrantTop)
			numberLabel.position = CGPointMake(0, (36+numeralDelta));
		else if (self.dateQuadrant == DateQuadrantBottom)
			numberLabel.position = CGPointMake(0, -(44+numeralDelta));
        else if (self.dateQuadrant == DateQuadrantHermes) // Special position for Hermes date # to fit the box
            numberLabel.position = CGPointMake(0, -(63+numeralDelta));

		[faceMarkings addChild:numberLabel];
	}
    
    if (self.monogramStyle == MonogramStyleRegular) // Normal monogram upper position
    {
        [faceMarkings addChild:[self setupMonogramWithFontSize:18 horizontalOffset:0 verticalOffset:32]];
    }
	else if (self.monogramStyle == MonogramStyleNike) // In place of Nike+ complication icon. Use any monogram you like, Apple Logo looks great and is default
    {
        [faceMarkings addChild:[self setupMonogramWithFontSize:24 horizontalOffset:32 verticalOffset:-80]];
    }
	[self addChild:faceMarkings];
}

-(void)updateDate
{
	if (self.dateStyle != DateStyleNone && self.dateStyle != DateStyleHermesSolid) // Don't show the date for these styles
	{
		NSDateFormatter * df = [[NSDateFormatter alloc] init];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]]];
		
		if (self.dateStyle == DateStyleDay) // Only show day of the week
		{
			[df setDateFormat:@"ccc"];
		}
        else if (self.dateStyle == DateStyleDate || self.dateStyle == DateStyleHermesDuo) // Only show date #
		{
			[df setDateFormat:@"d"];
		}
        else if (self.dateStyle == DateStyleDayDate) // Day of the week + date #
		{
			[df setDateFormat:@"ccc d"];
		}
		
        CGFloat dateFontSize;
        
        if (self.dateStyle == DateStyleHermesDuo) // Hermes date # is larger to fit the box
        {
            dateFontSize = 20;
            
            
            // **************************************************************************************************************************
            // I don't know why the following line always errors when switching between DesktopSim and running on an actual device, but just click the red icon and click "Fix" every time. Sigh.
            
            NSDictionary *attribs = @{NSFontAttributeName : [[NSFont systemFontOfSize:dateFontSize weight:UIFontWeightRegular] smallCaps], NSForegroundColorAttributeName : self.dateColor};
            // **************************************************************************************************************************
            
            
            NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:[[df stringFromDate:[NSDate date]] uppercaseString] attributes:attribs];
            
            SKLabelNode *dateLabelA = (SKLabelNode *)[[self childNodeWithName:@"Markings"] childNodeWithName:@"Date"];
            dateLabelA.attributedText = labelText;
            
            // Commenting B here fixes the glitch in the original code where masking didn't work on the date
            /*
            SKLabelNode *dateLabelB = (SKLabelNode *)[[self childNodeWithName:@"Markings Alternate"] childNodeWithName:@"Date"];
            dateLabelB.attributedText = labelText;
            */
        }
        else { // Regular date # size
            dateFontSize = 12;
            
            NSDictionary *attribs = @{NSFontAttributeName : [[NSFont systemFontOfSize:dateFontSize weight:NSFontWeightMedium] smallCaps], NSForegroundColorAttributeName : self.dateColor};
            
            NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:[[df stringFromDate:[NSDate date]] uppercaseString] attributes:attribs];
            
            // Commenting A here fixes the glitch in the original code where masking didn't work on the date
            /*
            SKLabelNode *dateLabelA = (SKLabelNode *)[[self childNodeWithName:@"Markings"] childNodeWithName:@"Date"];
            dateLabelA.attributedText = labelText;
            */
            SKLabelNode *dateLabelB = (SKLabelNode *)[[self childNodeWithName:@"Markings Alternate"] childNodeWithName:@"Date"];
            dateLabelB.attributedText = labelText;
        }
	}
}

- (SKLabelNode *)setupMonogramWithFontSize:(CGFloat)size horizontalOffset:(CGFloat)Xoffset verticalOffset:(CGFloat)Yoffset {
    NSDictionary *attribs = @{NSFontAttributeName : [NSFont systemFontOfSize:size weight:NSFontWeightMedium], NSForegroundColorAttributeName : self.monogramColor};
    
    NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:
                                     ![self.monogram isEqual: @""]? self.monogram : @" " // Empty labels trigger NSMutableRLEArray crashes, at least in the desktop shim, so we make it a space.
                                                                    attributes:attribs];
    
    SKLabelNode *monogramLabel = [SKLabelNode labelNodeWithAttributedText:labelText];
    monogramLabel.position = CGPointMake(Xoffset, Yoffset);
    
    return monogramLabel;
}

#pragma mark -

-(void)setupColors
{
	SKColor *colorRegionColor = nil;
	SKColor *faceBackgroundColor = nil;
	SKColor *majorMarkColor = nil;
	SKColor *minorMarkColor = nil;
	SKColor *inlayColor = nil;
    SKColor *dotColor = nil;
	SKColor *handColor = nil;
	SKColor *textColor = nil;
    SKColor *dateColor = nil;
    SKColor *monogramColor = nil;
	SKColor *secondHandColor = nil;
	
	SKColor *alternateMajorMarkColor = nil;
	SKColor *alternateMinorMarkColor = nil;
	SKColor *alternateTextColor = nil;

	self.useMasking = NO;
	
	switch (self.theme) {
    /* Hermes Duotone */
		case ThemeHermesDuoPink:
		{
            self.numeralStyle = NumeralStyleHermesDuo;
            self.dateStyle = DateStyleHermesDuo;
            self.dateQuadrant = DateQuadrantHermes;
            self.monogramStyle = MonogramStyleRegular;
            self.monogram = @" "; // e.g. 
            
			colorRegionColor = [SKColor colorWithRed:0.839 green:0.145 blue:0.310 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithRed:0.314 green:0.129 blue:0.176 alpha:1.000];
			majorMarkColor = [SKColor colorWithRed:0.831 green:0.540 blue:0.612 alpha:0.5];
			minorMarkColor = majorMarkColor;
            inlayColor = [SKColor colorWithRed:0.980 green:0.514 blue:0.608 alpha:1.000];
            dotColor = inlayColor;
			handColor = [SKColor whiteColor];
            textColor = inlayColor;
            dateColor = [SKColor colorWithRed:0.992 green:0.898 blue:0.796 alpha:1.000];
            monogramColor = textColor;
            secondHandColor = majorMarkColor;
			break;
		}
		case ThemeHermesDuoOrange:
		{
            self.numeralStyle = NumeralStyleHermesDuo;
            self.dateStyle = DateStyleHermesDuo;
            self.dateQuadrant = DateQuadrantHermes;
            self.monogramStyle = MonogramStyleRegular;
            self.monogram = @" "; // e.g. 
            
			colorRegionColor = [SKColor colorWithRed:0.878 green:0.831 blue:0.737 alpha:1.000];
            faceBackgroundColor = [SKColor colorWithRed:0.133 green:0.180 blue:0.247 alpha:1.000];
			inlayColor = [SKColor colorWithRed:1.000 green:0.450 blue:0.136 alpha:1.000];
            dotColor = inlayColor;
			majorMarkColor = [inlayColor colorWithAlphaComponent:0.5];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = inlayColor;
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = majorMarkColor;
			break;
		}
    /* Hermes Solid Num Black BG */
        case ThemeHermesSolidPink:
        {
            self.numeralStyle = NumeralStyleHermesSolid;
            self.dateStyle = DateStyleHermesSolid;
            self.dateQuadrant = DateQuadrantHermes;
            self.monogramStyle = MonogramStyleRegular;
            self.monogram = @" "; // e.g. 
            
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = majorMarkColor;
            inlayColor = colorRegionColor;
            dotColor = colorRegionColor;
            handColor = majorMarkColor;
            textColor = [SKColor colorWithRed:0.980 green:0.514 blue:0.608 alpha:1.000];
            dateColor = majorMarkColor;
            monogramColor = textColor;
            secondHandColor = textColor;
            break;
        }
        case ThemeHermesSolidOrange:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = majorMarkColor;
            inlayColor = colorRegionColor;
            dotColor = colorRegionColor;
            handColor = majorMarkColor;
            textColor = [SKColor colorWithRed:1.000 green:0.450 blue:0.136 alpha:1.000];
            dateColor = majorMarkColor;
            monogramColor = textColor;
            secondHandColor = textColor;
            break;
        }
        case ThemeHermesSolidGold:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithWhite:0.0 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            majorMarkColor = [SKColor colorWithRed:0.900 green:0.750 blue:0.550 alpha:1.000];
            minorMarkColor = majorMarkColor;
            inlayColor = [SKColor colorWithRed:1.000 green:0.925 blue:0.750 alpha:1.000];
            dotColor = colorRegionColor;
            handColor = majorMarkColor;
            textColor = majorMarkColor;
            dateColor = majorMarkColor;
            monogramColor = textColor;
            secondHandColor = textColor;
            break;
        }
        case ThemeHermesSolidWhite:
        {
            self.numeralStyle = NumeralStyleHermesSolid;
            self.dateStyle = DateStyleHermesSolid;
            self.dateQuadrant = DateQuadrantHermes;
            self.monogramStyle = MonogramStyleRegular;
            self.monogram = @" "; // e.g. 
            
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = majorMarkColor;
            inlayColor = colorRegionColor;
            dotColor = colorRegionColor;
            handColor = majorMarkColor;
            textColor = majorMarkColor;
            dateColor = majorMarkColor;
            monogramColor = textColor;
            secondHandColor = textColor;
            break;
        }
    /* Nike Sport */
        case ThemeNikeBlue:
        {
            self.numeralStyle = NumeralStyleNike;
            self.dateStyle = DateStyleNone;
            self.dateQuadrant = DateQuadrantRight;
            self.monogramStyle = MonogramStyleNike;
            self.monogram = @""; // e.g. 
            
            colorRegionColor = [SKColor colorWithRed:0.180 green:0.655 blue:0.863 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor whiteColor];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeBlueBlack:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor colorWithRed:0.180 green:0.655 blue:0.863 alpha:1.000];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeOrange:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithRed:0.933 green:0.396 blue:0.247 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor whiteColor];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeOrangeBlack:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor colorWithRed:0.933 green:0.396 blue:0.247 alpha:1.000];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeRed:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithRed:0.949 green:0.227 blue:0.188 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor whiteColor];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeRedBlack:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor colorWithRed:0.949 green:0.227 blue:0.188 alpha:1.000];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeNeon:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithRed:0.839 green:0.992 blue:0.259 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor blackColor];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeNeonBlack:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor colorWithRed:0.839 green:0.992 blue:0.259 alpha:1.000];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikePink:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithRed:0.988 green:0.800 blue:0.722 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor blackColor];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikePinkBlack:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor colorWithRed:0.988 green:0.800 blue:0.722 alpha:1.000];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
        case ThemeNikeSky:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithRed:0.569 green:0.855 blue:0.847 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor blackColor];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.933 green:0.396 blue:0.247 alpha:1.000];
            break;
        }
        case ThemeNikeSkyBlack:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor colorWithRed:0.569 green:0.855 blue:0.847 alpha:1.000];
            dateColor = textColor;
            monogramColor = [SKColor whiteColor];
            secondHandColor = [SKColor colorWithRed:0.933 green:0.396 blue:0.247 alpha:1.000];
            break;
        }
        case ThemeNikeNavy:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithRed:0.369 green:0.443 blue:0.490 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor blackColor];
            dateColor = textColor;
            monogramColor = [SKColor colorWithRed:0.906 green:0.376 blue:0.161 alpha:1.000];
            secondHandColor = monogramColor;
            break;
        }
        case ThemeNikeNavyBlack:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor colorWithRed:0.369 green:0.443 blue:0.490 alpha:1.000];
            dateColor = textColor;
            monogramColor = [SKColor colorWithRed:0.906 green:0.376 blue:0.161 alpha:1.000];
            secondHandColor = monogramColor;
            break;
        }
        case ThemeNikeWhite:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor colorWithRed:0.788 green:0.149 blue:0.149 alpha:1.000];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor colorWithRed:0.973 green:0.224 blue:0.196 alpha:1.000];
            minorMarkColor = majorMarkColor;
            handColor = [SKColor colorWithRed:0.973 green:0.224 blue:0.196 alpha:1.000];
            textColor = [SKColor colorWithRed:0.800 green:0.816 blue:0.827 alpha:1.000];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = [SKColor whiteColor];
            break;
        }
        case ThemeNikeBlack:
        {
            self.numeralStyle = NumeralStyleNike;
            self.dateStyle = DateStyleNone;
            self.dateQuadrant = DateQuadrantRight;
            self.monogramStyle = MonogramStyleNike;
            self.monogram = @""; // e.g. 
            
            colorRegionColor = [SKColor colorWithRed:0.227 green:0.227 blue:0.227 alpha:1.000];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor whiteColor];
            dotColor = [SKColor blackColor];
            majorMarkColor = [SKColor whiteColor];
            minorMarkColor = [SKColor whiteColor];
            handColor = [SKColor whiteColor];
            textColor = [SKColor blackColor];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = [SKColor colorWithRed:0.650 green:0.650 blue:0.650 alpha:1.000];
            break;
        }
    /* Regular Rectangle */
		case ThemeNavy:
		{
            self.numeralStyle = NumeralStyleAll;
            self.dateStyle = DateStyleDayDate;
            self.dateQuadrant = DateQuadrantRight;
            self.monogramStyle = MonogramStyleRegular;
            self.monogram = @""; // e.g. 
            
			colorRegionColor = [SKColor colorWithRed:0.067 green:0.471 blue:0.651 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithRed:0.118 green:0.188 blue:0.239 alpha:1.000];
			inlayColor = colorRegionColor;
            dotColor = colorRegionColor;
			majorMarkColor = [SKColor whiteColor];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = [SKColor whiteColor];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = majorMarkColor;
			break;
		}
        case ThemeContrast:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor whiteColor];
            faceBackgroundColor = colorRegionColor;
            inlayColor = colorRegionColor;
            dotColor = inlayColor;
            majorMarkColor = [SKColor blackColor];
            minorMarkColor = majorMarkColor;
            handColor = [SKColor blackColor];
            textColor = [SKColor blackColor];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = majorMarkColor;
            break;
        }
        case ThemeLiquid:
        {
            // Don't need to set up face attributes here, they're same as one before and after
            colorRegionColor = [SKColor colorWithWhite:0.2 alpha:1.0];
            faceBackgroundColor = colorRegionColor;
            inlayColor = [SKColor colorWithWhite:0.3 alpha:1.0];
            dotColor = colorRegionColor;
            majorMarkColor = [SKColor colorWithWhite:0.5 alpha:1.0];
            minorMarkColor = majorMarkColor;
            handColor = [SKColor whiteColor];
            textColor = [SKColor whiteColor];
            dateColor = textColor;
            monogramColor = textColor;
            secondHandColor = majorMarkColor;
            break;
        }
		case ThemeNoir:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
			inlayColor = faceBackgroundColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor whiteColor];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = [SKColor whiteColor];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = majorMarkColor;
			break;
		}
		case ThemeVictoire:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.749 green:0.291 blue:0.319 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithRed:0.391 green:0.382 blue:0.340 alpha:1.000];
			inlayColor = [SKColor colorWithRed:0.649 green:0.191 blue:0.219 alpha:1.000];
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithRed:0.937 green:0.925 blue:0.871 alpha:1.000];
			minorMarkColor = majorMarkColor;
			handColor = majorMarkColor;
			textColor = majorMarkColor;
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = [SKColor colorWithRed:0.949 green:0.491 blue:0.619 alpha:1.000];
			break;
		}
		case ThemeAngler:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor blackColor];
            faceBackgroundColor = colorRegionColor;
			inlayColor = [SKColor colorWithRed:0.180 green:0.800 blue:0.482 alpha:1.000];
            dotColor = colorRegionColor;
			majorMarkColor = inlayColor;
			minorMarkColor = majorMarkColor;
			handColor = [inlayColor colorWithAlphaComponent:0.4];
			textColor = inlayColor;
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = majorMarkColor;
			break;
		}
		case ThemeDelay:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.941 green:0.408 blue:0.231 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithWhite:0.282 alpha:1.000];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithRed:0.941 green:0.708 blue:0.531 alpha:1.000];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = handColor;
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = majorMarkColor;
			break;
		}
		case ThemeLuxe:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithWhite:0.082 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithWhite:0.082 alpha:1.000];
			inlayColor = [SKColor colorWithRed:0.969 green:0.878 blue:0.780 alpha:1.000];
            dotColor = colorRegionColor;
			majorMarkColor = [SKColor colorWithRed:0.804 green:0.710 blue:0.639 alpha:1.000];
			minorMarkColor = majorMarkColor;
			handColor = majorMarkColor;
			textColor = handColor;
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = inlayColor;
			break;
		}
		case ThemeSage:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.357 green:0.678 blue:0.600 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithRed:0.264 green:0.346 blue:0.321 alpha:1.000];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithRed:0.607 green:0.754 blue:0.718 alpha:1.000];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = handColor;
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = inlayColor;
			break;
		}
		case ThemeBondi:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.086 green:0.584 blue:0.706 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithWhite:0.9 alpha:1];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithWhite:0.9 alpha:1.0];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = [SKColor colorWithWhite:1.0 alpha:1.0];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = [SKColor colorWithRed:0.486 green:0.784 blue:0.906 alpha:1.000];
			
			alternateTextColor = [SKColor colorWithWhite:0.6 alpha:1];
			alternateMinorMarkColor = [SKColor colorWithWhite:0.6 alpha:1];
			alternateMajorMarkColor = [SKColor colorWithWhite:0.6 alpha:1];
			
			self.useMasking = YES;
			break;
		}
		case ThemeTangerine:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.992 green:0.502 blue:0.192 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithWhite:0.9 alpha:1];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithWhite:0.9 alpha:1.0];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = [SKColor colorWithWhite:1.0 alpha:1.0];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = [SKColor colorWithRed:0.992 green:0.702 blue:0.392 alpha:1.000];
			
			alternateTextColor = [SKColor colorWithWhite:0.6 alpha:1];
			alternateMinorMarkColor = [SKColor colorWithWhite:0.6 alpha:1];
			alternateMajorMarkColor = [SKColor colorWithWhite:0.6 alpha:1];
			
			self.useMasking = YES;
			break;
		}
		case ThemeStrawberry:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.831 green:0.161 blue:0.420 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithWhite:0.9 alpha:1];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithWhite:0.9 alpha:1.0];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = [SKColor colorWithWhite:1.0 alpha:1];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = [SKColor colorWithRed:0.912 green:0.198 blue:0.410 alpha:1.000];
			
			alternateTextColor = [SKColor colorWithWhite:0.6 alpha:1];
			alternateMinorMarkColor = [SKColor colorWithWhite:0.6 alpha:1];
			alternateMajorMarkColor = [SKColor colorWithWhite:0.6 alpha:1];
			
			self.useMasking = YES;
			break;
		}
		case ThemePawn:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.196 green:0.329 blue:0.275 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithRed:0.846 green:0.847 blue:0.757 alpha:1.000];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithRed:0.365 green:0.580 blue:0.506 alpha:1.000];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = [SKColor colorWithWhite:1.0 alpha:1];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = [SKColor colorWithRed:0.912 green:0.198 blue:0.410 alpha:1.000];
			
			alternateTextColor = colorRegionColor;
			alternateMinorMarkColor = colorRegionColor;
			alternateMajorMarkColor = colorRegionColor;
			
			self.useMasking = YES;
			break;
		}
		case ThemeRoyal:
		{
            // Don't need to set up face attributes here, they're same as one before and after
			colorRegionColor = [SKColor colorWithRed:0.118 green:0.188 blue:0.239 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithWhite:0.9 alpha:1.0];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithRed:0.318 green:0.388 blue:0.539 alpha:1.000];
			minorMarkColor = majorMarkColor;
			handColor = [SKColor whiteColor];
			textColor = [SKColor colorWithWhite:0.9 alpha:1];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = [SKColor colorWithRed:0.912 green:0.198 blue:0.410 alpha:1.000];
			
			alternateTextColor = [SKColor colorWithRed:0.218 green:0.288 blue:0.439 alpha:1.000];
			alternateMinorMarkColor = alternateTextColor;
			alternateMajorMarkColor = alternateTextColor;
			
			self.useMasking = YES;
			break;
		}
		case ThemeMarques:
		{
            self.numeralStyle = NumeralStyleAll;
            self.dateStyle = DateStyleDayDate;
            self.dateQuadrant = DateQuadrantRight;
            self.monogramStyle = MonogramStyleRegular;
            self.monogram = @""; // e.g. 
            
			colorRegionColor = [SKColor colorWithRed:0.886 green:0.141 blue:0.196 alpha:1.000];
			faceBackgroundColor = [SKColor colorWithRed:0.145 green:0.157 blue:0.176 alpha:1.000];
			inlayColor = colorRegionColor;
            dotColor = inlayColor;
			majorMarkColor = [SKColor colorWithWhite:1 alpha:0.8];
			minorMarkColor = [faceBackgroundColor colorWithAlphaComponent:0.5];
			handColor = [SKColor whiteColor];
			textColor = [SKColor colorWithWhite:1 alpha:1];
            dateColor = textColor;
            monogramColor = textColor;
			secondHandColor = [SKColor colorWithWhite:0.9 alpha:1];
			break;
             
		}
		default:
			break;
	}
	
	self.colorRegionColor = colorRegionColor;
	self.faceBackgroundColor = faceBackgroundColor;
	self.majorMarkColor = majorMarkColor;
	self.minorMarkColor = minorMarkColor;
	self.inlayColor = inlayColor;
    self.dotColor = dotColor;
	self.textColor = textColor;
    self.dateColor = dateColor;
    self.monogramColor = monogramColor;
	self.handColor = handColor;
	self.secondHandColor = secondHandColor;
	
	self.alternateMajorMarkColor = alternateMajorMarkColor;
	self.alternateMinorMarkColor = alternateMinorMarkColor;
	self.alternateTextColor = alternateTextColor;
}

-(void)setupScene
{
	SKNode *face = [self childNodeWithName:@"Face"];
	
	SKSpriteNode *hourHand = (SKSpriteNode *)[face childNodeWithName:@"Hours"];
	SKSpriteNode *minuteHand = (SKSpriteNode *)[face childNodeWithName:@"Minutes"];
	
	SKSpriteNode *hourHandInlay = (SKSpriteNode *)[hourHand childNodeWithName:@"Hours Inlay"];
	SKSpriteNode *minuteHandInlay = (SKSpriteNode *)[minuteHand childNodeWithName:@"Minutes Inlay"];
	
	SKSpriteNode *secondHand = (SKSpriteNode *)[face childNodeWithName:@"Seconds"];
	SKSpriteNode *colorRegion = (SKSpriteNode *)[face childNodeWithName:@"Color Region"];
	SKSpriteNode *colorRegionReflection = (SKSpriteNode *)[face childNodeWithName:@"Color Region Reflection"];
    SKSpriteNode *centerDot = (SKSpriteNode *)[face childNodeWithName:@"Center Dot"];
	SKSpriteNode *staticImageLayer = (SKSpriteNode *)[[face childNodeWithName:@"Image Root"] childNodeWithName:@"Static Image Layer"];
    SKSpriteNode *nikeImageLayer = (SKSpriteNode *)[[face childNodeWithName:@"Image Root"] childNodeWithName:@"Nike Numbers"];
    SKSpriteNode *hermesDuoNumImageLayer = (SKSpriteNode *)[[face childNodeWithName:@"Image Root"] childNodeWithName:@"Hermes Duo Numbers"];
    SKSpriteNode *hermesDuoDateImageLayer = (SKSpriteNode *)[[face childNodeWithName:@"Image Root"] childNodeWithName:@"Hermes Duo Date"];
    SKSpriteNode *hermesSolidNumImageLayer = (SKSpriteNode *)[[face childNodeWithName:@"Image Root"] childNodeWithName:@"Hermes Solid Numbers"];
    SKSpriteNode *hermesSolidDateImageLayer = (SKSpriteNode *)[[face childNodeWithName:@"Image Root"] childNodeWithName:@"Hermes Solid Date"];
	
	SKSpriteNode *centerDisc = (SKSpriteNode *)[face childNodeWithName:@"Center Disc"];

	hourHand.color = self.handColor;
	hourHand.colorBlendFactor = 1.0;
	
	minuteHand.color = self.handColor;
	minuteHand.colorBlendFactor = 1.0;
	
	secondHand.color = self.secondHandColor;
	secondHand.colorBlendFactor = 1.0;
	
	self.backgroundColor = self.faceBackgroundColor;
	
	colorRegion.color = self.colorRegionColor;
	colorRegion.colorBlendFactor = 1.0;
    
    centerDot.color = self.dotColor;
    centerDot.colorBlendFactor = 1.0;
	
	staticImageLayer.color = self.textColor;
	staticImageLayer.colorBlendFactor = 1.0;
    
    nikeImageLayer.color = self.textColor;
    nikeImageLayer.colorBlendFactor = 1.0;
    
    hermesDuoNumImageLayer.color = self.textColor;
    hermesDuoNumImageLayer.colorBlendFactor = 1.0;
    hermesDuoDateImageLayer.color = self.dateColor;
    hermesDuoDateImageLayer.colorBlendFactor = 1.0;

    hermesSolidNumImageLayer.color = self.textColor;
    hermesSolidNumImageLayer.colorBlendFactor = 1.0;
    hermesSolidDateImageLayer.color = self.dateColor;
    hermesSolidDateImageLayer.colorBlendFactor = 1.0;

	hourHandInlay.color = self.inlayColor;
	hourHandInlay.colorBlendFactor = 1.0;
	
	minuteHandInlay.color = self.inlayColor;
	minuteHandInlay.colorBlendFactor = 1.0;
	
	CGFloat colorRegionScale = 0.9;
	
	if (self.colorRegionStyle == ColorRegionStyleNone)
	{
		colorRegion.alpha = 0.0;
		
	}
	else if (self.colorRegionStyle == ColorRegionStyleDynamicDuo)
	{
		colorRegion.alpha = 1.0;
		colorRegion.texture = nil;
		colorRegion.anchorPoint = CGPointMake(0.5, 0);
		colorRegion.size = CGSizeMake(768, 768);

		colorRegionReflection.texture = nil;

	}
	else if (self.colorRegionStyle == ColorRegionStyleHalf)
	{
		colorRegion.alpha = 1.0;
		colorRegion.texture = nil;
		colorRegion.anchorPoint = CGPointMake(0.5, 0);
		colorRegion.size = CGSizeMake(768, 768);

		colorRegionReflection.texture = nil;

	}
	else if (self.colorRegionStyle == ColorRegionStyleCircle)
	{
		colorRegion.texture = [SKTexture textureWithImageNamed:@"ColorRegionCircle"];
		colorRegion.anchorPoint = CGPointMake(0.5, 0.5);
		colorRegion.position = CGPointZero;
		colorRegion.size = CGSizeMake(179*colorRegionScale, 179*colorRegionScale);
		
		colorRegionReflection.texture = [SKTexture textureWithImageNamed:@"ColorRegionCircleReflection"];
		colorRegionReflection.anchorPoint = CGPointMake(0.5, 0.5);
		colorRegionReflection.position = CGPointZero;
		colorRegionReflection.size = CGSizeMake(368*colorRegionScale, 448*colorRegionScale);
	}
	else if (self.colorRegionStyle == ColorRegionStyleRing)
	{
		colorRegion.texture = [SKTexture textureWithImageNamed:@"ColorRegionRing"];
		colorRegion.anchorPoint = CGPointMake(0.5, 0.5);
		colorRegion.position = CGPointZero;
		colorRegion.size = CGSizeMake(179*colorRegionScale, 179*colorRegionScale);
		
		colorRegionReflection.texture = [SKTexture textureWithImageNamed:@"ColorRegionRingReflection"];
		colorRegionReflection.anchorPoint = CGPointMake(0.5, 0.5);
		colorRegionReflection.position = CGPointZero;
		colorRegionReflection.size = CGSizeMake(368*colorRegionScale, 448*colorRegionScale);
	}
	
    if (self.numeralStyle == NumeralStyleMAX) // Never gets used tbh, it doesn't look great.
    {
        staticImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 1.0;
        nikeImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        
        hermesDuoNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesDuoDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;

        hermesSolidNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesSolidDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
    }
    else if (self.numeralStyle == NumeralStyleNike) // Show Nike images, hide all others
    {
        staticImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        nikeImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 1.0;
        
        hermesDuoNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesDuoDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;

        hermesSolidNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesSolidDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
    }
    else if (self.numeralStyle == NumeralStyleHermesDuo) // Show Hermes Duo imagess, hide all others
    {
        staticImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        nikeImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        
        hermesDuoNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 1.0;
        hermesDuoDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 1.0;

        hermesSolidNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesSolidDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
    }
    else if (self.numeralStyle == NumeralStyleHermesSolid) // Show Hermes Solid images, hide all others
    {
        staticImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        nikeImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        
        hermesDuoNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesDuoDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;

        hermesSolidNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 1.0;
        hermesSolidDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 1.0;
    }
    else { // Regular text-based face, hide all images
        staticImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        nikeImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        
        hermesDuoNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesDuoDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;

        hermesSolidNumImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
        hermesSolidDateImageLayer.alpha = self.useBackgroundImageOverlay ? 1.0 : 0.0;
    }

	
	if (self.faceStyle == FaceStyleRound)
	{
		[self setupTickmarksForRoundFaceWithLayerName:@"Markings"];
	}
	else
	{
		[self setupTickmarksForRectangularFaceWithLayerName:@"Markings"];
	}
	
	if (self.centerDiscStyle == CenterDiscStyleEnabled)
	{
		centerDisc.alpha = 1.0;
	}
	else
	{
		centerDisc.alpha = 0.0;
	}
	
	colorRegionReflection.alpha = 0;
}


-(void)setupMasking
{
	SKCropNode *faceMarkings = (SKCropNode *)[self childNodeWithName:@"Markings"];
	SKNode *face = [self childNodeWithName:@"Face"];
	
	SKNode *colorRegion = [face childNodeWithName:@"Color Region"];
	SKNode *colorRegionReflection = [face childNodeWithName:@"Color Region Reflection"];
	
	faceMarkings.maskNode = colorRegion;
	
	self.textColor = self.alternateTextColor;
    self.monogramColor = self.alternateTextColor;
    self.dateColor = self.alternateTextColor;
    self.minorMarkColor = self.alternateMinorMarkColor;
	self.majorMarkColor = self.alternateMajorMarkColor;
	
	
	if (self.faceStyle == FaceStyleRound)
	{
		[self setupTickmarksForRoundFaceWithLayerName:@"Markings Alternate"];
	}
	else
	{
		[self setupTickmarksForRectangularFaceWithLayerName:@"Markings Alternate"];
	}
	
	SKCropNode *alternateFaceMarkings = (SKCropNode *)[self childNodeWithName:@"Markings Alternate"];
	colorRegionReflection.alpha = 1;
	alternateFaceMarkings.maskNode = colorRegionReflection;
}

#pragma mark -

- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene
{
	[self updateHands];
	[self updateDate];
}

-(void)updateHands
{
#if PREPARE_SCREENSHOT
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:11280+30]; // 10:08:30am in EST Time Zone
#else
	NSDate *now = [NSDate date];
#endif
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond| NSCalendarUnitNanosecond) fromDate:now];
	
	SKNode *face = [self childNodeWithName:@"Face"];
	
	SKNode *hourHand = [face childNodeWithName:@"Hours"];
	SKNode *minuteHand = [face childNodeWithName:@"Minutes"];
	SKNode *secondHand = [face childNodeWithName:@"Seconds"];
	
	SKNode *colorRegion = [face childNodeWithName:@"Color Region"];
	SKNode *colorRegionReflection = [face childNodeWithName:@"Color Region Reflection"];

	hourHand.zRotation =  - (2*M_PI)/12.0 * (CGFloat)(components.hour%12 + 1.0/60.0*components.minute);
	minuteHand.zRotation =  - (2*M_PI)/60.0 * (CGFloat)(components.minute + 1.0/60.0*components.second);
	secondHand.zRotation = - (2*M_PI)/60 * (CGFloat)(components.second + 1.0/NSEC_PER_SEC*components.nanosecond);
	
	if (self.colorRegionStyle == ColorRegionStyleNone)
	{

	}
	else if (self.colorRegionStyle == ColorRegionStyleDynamicDuo)
	{
		colorRegion.alpha = 1.0;
		
		colorRegion.zRotation =  M_PI_2 -(2*M_PI)/60.0 * (CGFloat)(components.minute + 1.0/60.0*components.second);
		colorRegionReflection.zRotation =  M_PI_2 - (2*M_PI)/60.0 * (CGFloat)(components.minute + 1.0/60.0*components.second);
	}
	else if (self.colorRegionStyle == ColorRegionStyleHalf)
	{
		colorRegion.alpha = 1.0;

		colorRegion.zRotation =  0;
		colorRegionReflection.zRotation =  0;

	}
	else if (self.colorRegionStyle == ColorRegionStyleCircle)
	{
		colorRegion.zRotation =  0;
		colorRegionReflection.zRotation =  0;
	}
	else if (self.colorRegionStyle == ColorRegionStyleRing)
	{
		colorRegion.zRotation =  0;
		colorRegionReflection.zRotation =  0;
	}
}

-(void)refreshTheme
{
	[[NSUserDefaults standardUserDefaults] setInteger:self.theme forKey:@"Theme"];
	
	SKNode *existingMarkings = [self childNodeWithName:@"Markings"];
	SKNode *existingDualMaskMarkings = [self childNodeWithName:@"Markings Alternate"];

	[existingMarkings removeAllChildren];
	[existingMarkings removeFromParent];
	
	[existingDualMaskMarkings removeAllChildren];
	[existingDualMaskMarkings removeFromParent];
	
	[self setupColors];
	[self setupScene];
	
	if (self.useMasking && ((self.colorRegionStyle == ColorRegionStyleDynamicDuo) || (self.colorRegionStyle == ColorRegionStyleHalf)))
	{
		[self setupMasking];
	}
}

#pragma mark -

#if TARGET_OS_OSX
- (void)keyDown:(NSEvent *)event
{
	char key = event.characters.UTF8String[0];
	
	if (key == 't')
	{
		int direction = 1;
		
		if ((self.theme+direction > 0) && (self.theme+direction < ThemeMAX))
			self.theme += direction;
		else
			self.theme = 0;
	}
	else if (key == 'f')
	{
		if ((self.faceStyle+1 > 0) && (self.faceStyle+1 < FaceStyleMAX))
			self.faceStyle ++;
		else
			self.faceStyle = 0;
	}
	else if (key == 'n')
	{
		if ((self.numeralStyle+1 > 0) && (self.numeralStyle+1 < NumeralStyleMAX))
			self.numeralStyle ++;
		else
			self.numeralStyle = 0;
	}
	else if (key == '0')
	{
		if ((self.tickmarkStyle+1 > 0) && (self.tickmarkStyle+1 < TickmarkStyleMAX))
			self.tickmarkStyle ++;
		else
			self.tickmarkStyle = 0;
	}
	else if (key == '-')
	{
		if ((self.minorTickmarkShape+1 > 0) && (self.minorTickmarkShape+1 < TickmarkShapeMAX))
			self.minorTickmarkShape ++;
		else
			self.minorTickmarkShape = 0;
	}
	else if (key == '=')
	{
		if ((self.majorTickmarkShape+1 > 0) && (self.majorTickmarkShape+1 < TickmarkShapeMAX))
			self.majorTickmarkShape ++;
		else
			self.majorTickmarkShape = 0;
	}
	else if (key == 'r')
	{
		if ((self.colorRegionStyle+1 > 0) && (self.colorRegionStyle+1 < ColorRegionStyleMAX))
			self.colorRegionStyle ++;
		else
			self.colorRegionStyle = 0;
	}
	else if (key == 'd')
	{
		if ((self.dateStyle+1 > 0) && (self.dateStyle+1 < DateStyleMAX))
			self.dateStyle ++;
		else
			self.dateStyle = 0;
	}
	else if (key == 'q')
	{
		if ((self.dateQuadrant+1 > 0) && (self.dateQuadrant+1 < DateQuadrantMAX))
			self.dateQuadrant ++;
		else
			self.dateQuadrant = 0;
	}
	else if (key == 'c')
	{
		if ((self.centerDiscStyle+1 > 0) && (self.centerDiscStyle+1 < CenterDiscStyleMAX))
			self.centerDiscStyle ++;
		else
			self.centerDiscStyle = 0;
	}
	else if (key == 'p')
	{
		self.useBackgroundImageOverlay = !self.useBackgroundImageOverlay;
	}
	else if (key == 'x')
	{
		
		self.theme = arc4random()%ThemeMAX;
		self.faceStyle = arc4random()%FaceStyleMAX;
		self.numeralStyle = arc4random()%NumeralStyleMAX;
		self.tickmarkStyle = arc4random()%TickmarkStyleMAX;
		self.minorTickmarkShape = arc4random()%TickmarkShapeMAX;
		self.majorTickmarkShape = arc4random()%TickmarkShapeMAX;
		self.colorRegionStyle = arc4random()%ColorRegionStyleMAX;

		self.dateStyle = arc4random()%DateStyleMAX;
		self.dateQuadrant = arc4random()%DateQuadrantMAX;

		self.centerDiscStyle = arc4random()%CenterDiscStyleMAX;
	}
	else if (key == 'z')
	{
		self.faceStyle = arc4random()%FaceStyleMAX;
		self.numeralStyle = arc4random()%NumeralStyleMAX;
		self.tickmarkStyle = arc4random()%TickmarkStyleMAX;
		self.minorTickmarkShape = arc4random()%TickmarkShapeMAX;
		self.majorTickmarkShape = arc4random()%TickmarkShapeMAX;
		self.colorRegionStyle = arc4random()%ColorRegionStyleMAX;
		
		self.dateStyle = arc4random()%DateStyleMAX;
		self.dateQuadrant = arc4random()%DateQuadrantMAX;
		
		self.centerDiscStyle = arc4random()%CenterDiscStyleMAX;
	}
	
	[self refreshTheme];
}
#endif
@end
