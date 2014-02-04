#import "cocos2d.h"

@class FxAnimatedSprite;

/** FxSprite is used by FxAnimatedSprite for individual elements of animation */
@interface FxSprite : CCSprite {
    NSString* lastSetFrameName;
}

/** Flash-ported tintPercent value. 0.0 <-> 1.0 range */
@property (nonatomic) ccColor4F tintPercent;
/** Flash-ported tintOffset value. -1.0 <-> 1.0 range */
@property (nonatomic) ccColor4F tintOffset;
/** Holds the name of layer this FxSprite is attached to */
@property (nonatomic, copy) NSString* name;

-(void)setSpriteFrameName:(NSString*)spf withOffsetRect:(CGRect)offsetRect;
-(void)applyAnimSprite:(FxAnimatedSprite*)sprite asLayerIndex:(NSInteger)layerIndex atFrame:(CGFloat)time wrapAround:(BOOL)wrapAround;
+(void)loadShader;

@end
