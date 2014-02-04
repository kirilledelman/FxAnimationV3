#import "cocos2d.h"
#import "FxAnimation.h"
#import "FxSprite.h"

typedef NS_ENUM(NSInteger, FxSpriteAnimMode) {
    FxSpriteAnimModeStopped,
    FxSpriteAnimModePlayOnce,
    FxSpriteAnimModeLoop,
    FxSpriteAnimModeRepeat
};

#define FXSPRITE_STOPPED 0
#define FXSPRITE_PLAYONCE 1
#define FXSPRITE_LOOP 2
#define FXSPRITE_REPEAT 3


@interface FxAnimatedSprite : CCSprite {
    NSMutableArray* _layers;
    NSMutableDictionary* _layerOverrides;
}

@property (readonly) NSArray* layers;
@property (readonly) NSDictionary* layerOverrides;

@property (readonly) FxAnimation* currentAnimation;
@property (readonly) NSString* currentSequence;

/** Controls the speed of the animation. 0.5 = half speed, 2.0 = double speed. */
@property (nonatomic) CGFloat animationTimeDilation;
@property (readonly) CGFloat animationTime;
@property (readonly) NSInteger frameNumber;
@property (readonly) NSInteger repeatCount;
@property (readonly) FxSpriteAnimMode currentAnimMode;
/** box that encloses all of this sprite's animated layers, in local coordinate system. */
@property (readonly) CGRect bounds;

/** Interpolate last -> first frame when looping. */
@property (nonatomic) BOOL wrapEndOfLoop;

/** Executed when animation finishes after playAnim. */
@property (nonatomic, copy) void(^onAnimationFinished)(FxAnimatedSprite* sender);
/** Executed when animation finishes after loopAnim and repeatAnim. */
@property (nonatomic, copy) void(^onAnimationLoopFinished)(FxAnimatedSprite* sender);
/** Executed every frame of animation. */
@property (nonatomic, copy) void(^onFrameEntered)(FxAnimatedSprite* sender);
/** Executed when frame comment is encountered. */
@property (nonatomic, copy) void(^onFrameComment)(FxAnimatedSprite* sender, NSString* comment);

/** internal use */
-(BOOL)prepareForAnimWithPath:(NSString*)animPath;

/** Stops at the first frame of animPath */
-(void)gotoAndStop:(NSString*)animPath;
/** Stops at the frameOffset frame of animPath. */
-(void)gotoAndStop:(NSString*)animPath frameOffset:(NSInteger)f;
/** Play animPath once. */
-(void)playAnim:(NSString*)animPath;
/** Loop animPath forever. */
-(void)loopAnim:(NSString*)animPath;
/** Repeat animPath set number of times. */
-(void)repeatAnim:(NSString*)animPath times:(NSInteger)count;
/** Stops current animation. */
-(void)stopAnim;

/** Gets FxSprite that's attached to a named layer in this animation */
-(FxSprite*)layerByName:(NSString*)name;

/** Tells this FxAnimatedSprite to override layer's symbol with another symbol. E.g. replace character's head with a pumpkin, or hand with hand holding a gun. */
-(void)overrideLayer:(NSString*)layerName withSymbol:(NSString*)symb;
/** Clears all overrides */
-(void)clearOverrides;

// static 
/** Flag that means that low-res textures are used for non-retina. Affects internal scaling and animation. */
+(void)setTexturesAreHalfSized:(BOOL)hs;
/** Flag that means that low-res textures are used for non-retina. Set this to true when on non-retina. */
+(BOOL)texturesAreHalfSized;

@end
