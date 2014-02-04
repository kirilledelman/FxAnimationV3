#import "ccTypes.h"
#import "CCTextureCache.h"
#import "CCTexture_Private.h"
#import "HelloWorldScene.h"
#import "FxAnimatedSprite.h"

@implementation HelloWorldScene

/**
 
 This is an example of using FxAnimation classes.
 
 For info on how to export animation from Flash, see FlashAnimationExporter/fxport.jsfl file comments
 
 To use in your own project, just copy over, include
 FxSprite.*, FxAnimatedSprite.*, FxAnimation.*
 
 Tested with cocos2d V3 RC1
 
 If you find this animation library useful, please consider buying me a cup of coffee.
 http://gogoat.com/donate/
 
 If you have questions, email me at kirill.edelman@gmail.com.
 
 Enjoy!
 
 */

-(id) init {
    self = [super init];
    if(!self) return nil;
    
    // Enable touch handling on scene node
    self.userInteractionEnabled = YES;
    
    // load sprite sheets
    // sprite sheets generated using http://www.codeandweb.com/texturepacker - not free but awesome/worth it
    [[CCTextureCache sharedTextureCache] addPVRImage:@"tex1.pvr.ccz"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"tex1.plist"];

    // set retina flag
    if([UIScreen mainScreen].scale == 1.0){
        // non-retina
        [FxAnimatedSprite setTexturesAreHalfSized:true]; // set half-sized flag
    }
    
    // tell cocos2d that our textures have premultiplied alpha (your project may be different)
    [CCTexture PVRImagesHavePremultipliedAlpha:true];
    
    // dogzamples
    
    // create an animated sprite
    FxAnimatedSprite* dog1 = [FxAnimatedSprite node];
    dog1.position = ccp(self.contentSize.width * 0.5, self.contentSize.height * 0.8);
    dog1.scale = 0.5;
    dog1.animationTimeDilation = 0.25; // speed at which animation is played (25%)
    [self addChild:dog1];
    
    // Loop animation.
    // Animations are loaded at time of call, and cached.
    // If you need to preload an animation (and symbols it includes), use [FxAnimation animationNamed:@"whatever"];
    // Parameter here is filename/sequencename. Each file can have many sequences.
    // Symbols (graphics) in files can be shared, and are only loaded once.
    [dog1 loopAnim:@"trixie/run"];
    
    // another one, running in opposite direction
    FxAnimatedSprite* dog2 = [FxAnimatedSprite node];
    dog2.position = ccp(self.contentSize.width * 0.5, self.contentSize.height * 0.6);
    dog2.color = [CCColor colorWithCcColor3b:ccc3(255, 128, 255)]; // tinted purple
    dog2.scale = 0.5;
    dog2.scaleX = -0.5; // flipped X (and scaled down)
    dog2.animationTimeDilation = 0.5; // speed at which animation is played (50%)
    [self addChild:dog2];
    
    // repeat sequence 4 times
    [dog2 repeatAnim:@"trixie/run" times:4];
    
    // after that, execute code in block
    dog2.onAnimationFinished = ^(FxAnimatedSprite* sprite){
        // flip X, play animation again
        sprite.scaleX *= -1;
        [sprite repeatAnim:@"trixie/run" times:4];
    };
    
    // another dog
    FxAnimatedSprite* dog3 = [FxAnimatedSprite node];
    dog3.position = ccp(self.contentSize.width * 0.5, self.contentSize.height * 0.4);
    dog3.scale = 0.4;
    dog3.animationTimeDilation = 0.25; // 25% speed
    [self addChild:dog3];
    
    // loop animation
    [dog3 loopAnim:@"trixie/poop"];
    
    // call block every time animation sequences
    dog3.onAnimationLoopFinished = ^(FxAnimatedSprite* sprite){
        
        // get layer "tail" from animation
        FxSprite* tail = [sprite layerByName:@"tail"];
        
        // make another sprite
        FxAnimatedSprite *poo = [FxAnimatedSprite node];
        poo.scale = 0.5;
        poo.position = [sprite convertToWorldSpace:tail.position];
        [self addChild:poo z:(sprite.zOrder - 1)]; // add under dog3
        [poo loopAnim:@"poop/stink"];
        
        // use actions to move it, fade out, remove
        [poo runAction:
         [CCActionSequence actions:
          [CCActionMoveBy actionWithDuration:1.5 position:ccp(200, 0)],
          [CCActionFadeOut actionWithDuration:0.25],
          [CCActionCallBlock actionWithBlock:^{
             [poo removeFromParentAndCleanup:true];
         }], nil]
         ];
        
    };
    
    // another dog
    FxAnimatedSprite* dog4 = [FxAnimatedSprite node];
    dog4.position = ccp(self.contentSize.width * 0.5, self.contentSize.height * 0.2);
    dog4.scale = 0.6;
    [self addChild:dog4];
    [dog4 loopAnim:@"trixie/run"];
    
    // to replace a symbol in layer with another symbol, use overrideLayer
    // if the symbol is from another animation, make sure it's cached/loaded first
    [FxAnimation animationNamed:@"poop"];
    // this could be used to swap out character's suit, for example
    [dog4 overrideLayer:@"front leg 1" withSymbol:@"poo_fly"];
    [dog4 overrideLayer:@"front leg 2" withSymbol:@"poo_fly"];
    [dog4 overrideLayer:@"back leg 1" withSymbol:@"poo_fly"];
    [dog4 overrideLayer:@"back leg 2" withSymbol:@"poo_fly"];
    
    // You can also add child CCNodes to FxNodes, which lets you
    // put a gun in character's hand, for example.
    CCLabelTTF* label = [CCLabelTTF labelWithString:@"Trixie" fontName:@"Courier" fontSize:20];
    label.position = ccp(0, 120);
    FxSprite* head = [dog4 layerByName:@"head"];
    [head addChild:label];
    
	return self;
}

+(HelloWorldScene *)scene {
    return [[self alloc] init];
}

#pragma mark - Enter & Exit

-(void)onEnter {
    // always call super onEnter first
    [super onEnter];
}

-(void)onExit {
    // always call super onExit last
    [super onExit];
}

@end