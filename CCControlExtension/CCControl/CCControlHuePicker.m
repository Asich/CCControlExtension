/*
 * CCControlHuePicker.m
 *
 * Copyright 2012 Stewart Hamilton-Arrandale.
 * http://creativewax.co.uk
 *
 * Modified by Yannick Loriot.
 * http://yannickloriot.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "CCControlHuePicker.h"
#import "Utils.h"
#import "ARCMacro.h"

@interface CCControlHuePicker ()
@property (nonatomic, strong) CCSprite    *background;
@property (nonatomic, strong) CCSprite    *slider;
@property (nonatomic, assign) CGPoint     startPos;

- (void)updateSliderPosition:(CGPoint)location;
- (BOOL)checkSliderPosition:(CGPoint)location;
    
@end
    
@implementation CCControlHuePicker
@synthesize background      = _background;
@synthesize slider          = _slider;
@synthesize startPos        = _startPos;
@synthesize hue             = _hue;
@synthesize huePercentage   = _huePercentage;

- (void)dealloc
{
    [self removeAllChildrenWithCleanup:YES];
    
    SAFE_ARC_RELEASE(_background);
    SAFE_ARC_RELEASE(_slider);
    
	SAFE_ARC_SUPER_DEALLOC();
}

- (id)initWithTarget:(id)target withPos:(CGPoint)pos
{
    if ((self = [super init]))
    {
        // Add background and slider sprites
        self.background     = [Utils addSprite:@"huePickerBackground.png" toTarget:target withPos:pos andAnchor:ccp(0, 0)];
        self.slider         = [Utils addSprite:@"colourPicker.png" toTarget:target withPos:pos andAnchor:ccp(0.5f, 0.5f)];
        
        _slider.position    = ccp(pos.x, pos.y + _background.boundingBox.size.height * 0.5f);
        
        _startPos           = pos;
        
        // Sets the default value
        _hue                = 0.0f;
        _huePercentage      = 0.0f;
    }
    return self;
}

- (void)setHue:(CGFloat)hueValue
{
    _hue                = hueValue;
    
    // Set the position of the slider to the correct hue
    // We need to divide it by 360 as its taken as an angle in degrees
    float huePercentage	= hueValue / 360.0f;
    
    // update
    [self setHuePercentage:huePercentage];
}

- (void)setHuePercentage:(CGFloat)hueValueInPercent_
{
    _huePercentage          = hueValueInPercent_;
    _hue                    = hueValueInPercent_ * 360.0f;
    
    // Clamp the position of the icon within the circle
    CGRect backgroundBox    = _background.boundingBox;
    
    // Get the center point of the background image
    float centerX           = _startPos.x + backgroundBox.size.width * 0.5f;
    float centerY           = _startPos.y + backgroundBox.size.height * 0.5f;
    
    // Work out the limit to the distance of the picker when moving around the hue bar
    float limit             = backgroundBox.size.width * 0.5f - 15.0f;
    
    // Update angle
    float angleDeg          = _huePercentage * 360.0f - 180.0f;
    float angle             = CC_DEGREES_TO_RADIANS(angleDeg);
    
    // Set new position of the slider
    float x                 = centerX + limit * cosf(angle);
    float y                 = centerY + limit * sinf(angle);
    _slider.position        = ccp(x, y);
}

- (void)setEnabled:(BOOL)enabled
{
    super.enabled   = enabled;
    
    _slider.opacity = enabled ? 255.0f : 128.0f;
}

#pragma mark -
#pragma mark CCControlHuePicker Public Methods

#pragma mark CCControlHuePicker Private Methods

- (void)updateSliderPosition:(CGPoint)location
{
    // Clamp the position of the icon within the circle
    CGRect backgroundBox    = _background.boundingBox;
    
    // get the center point of the background image
    float centerX           = _startPos.x + backgroundBox.size.width * 0.5f;
    float centerY           = _startPos.y + backgroundBox.size.height * 0.5f;
    
    // Work out the distance difference between the location and center
    float dx                = location.x - centerX;
    float dy                = location.y - centerY;
    
    // Update angle by using the direction of the location
    float angle             = atan2f(dy, dx);
    float angleDeg          = CC_RADIANS_TO_DEGREES(angle) + 180.0f;
    
    // Use the position / slider width to determin the percentage the dragger is at
    self.hue                = angleDeg;
    
	// Send CCControl callback
    [self sendActionsForControlEvents:CCControlEventValueChanged];
}

- (BOOL)checkSliderPosition:(CGPoint)location
{
    // Compute the distance between the current location and the center
    double distance = sqrt(pow (location.x + 10, 2) + pow(location.y, 2));
    
    // Check that the touch location is within the circle
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && (78 > distance && distance > 56))
        || (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && (160 > distance && distance > 118)))
#else
    if (160 > distance && distance > 118)
#endif
    {
        [self updateSliderPosition:location];
        
        return YES;
    }
    return NO;
}


#pragma mark -
#pragma mark CCTargetedTouch Delegate Methods

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (![self isEnabled])
    {
        return NO;
    }
    
    // Get the touch location
    CGPoint touchLocation   = [self touchLocation:touch];
	
    // Check the touch position on the slider
    return [self checkSliderPosition:touchLocation];
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Get the touch location
    CGPoint touchLocation   = [self touchLocation:touch];
	
    // Check the touch position on the slider
    [self checkSliderPosition:touchLocation];
}

#elif __MAC_OS_X_VERSION_MAX_ALLOWED

- (BOOL)ccMouseDown:(NSEvent *)event
{
    if (![self isEnabled])
    {
        return NO;
    }
    
    // Get the event location
    CGPoint eventLocation   = [self eventLocation:event];

    // Check the touch position on the slider
    return [self checkSliderPosition:eventLocation];
}

- (BOOL)ccMouseDragged:(NSEvent *)event
{
    if (![self isEnabled])
    {
        return NO;
    }
    
	// Get the event location
    CGPoint eventLocation   = [self eventLocation:event];
	
    // Check the touch position on the slider
    return [self checkSliderPosition:eventLocation];
}

#endif

@end
