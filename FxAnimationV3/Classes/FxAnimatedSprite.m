#import "FxAnimatedSprite.h"

@implementation FxAnimatedSprite

@synthesize layers=_layers, layerOverrides=_layerOverrides;

-(id)init{
    self = [super init];
    
    _layers = [[NSMutableArray alloc] init];
    _layerOverrides = [[NSMutableDictionary alloc] init];
    _animationTimeDilation = 1.0;
    _wrapEndOfLoop = true;
    _cascadeColorEnabled = _cascadeOpacityEnabled = true;
    _anchorPoint = ccp(0, 0);
    
#if CC_SPRITE_DEBUG_DRAW == 1
    CCLabelTTF* origin = [CCLabelTTF labelWithString:@"+" fontName:@"Courier" fontSize:12];
    origin.anchorPoint = ccp(0.5, 0.5);
    origin.position = ccp(0, 0);
    [self addChild:origin z:10000];
#endif
    
    return self;
}

-(void)dealloc{
}

/** will draw bounding box if in debug mode */
-(void)draw{
#if CC_SPRITE_DEBUG_DRAW == 1
	// draw bounding box
	CGPoint vertices[4]={
		ccp(_bounds.origin.x, _bounds.origin.y),
		ccp(_bounds.origin.x, _bounds.origin.y + _bounds.size.height),
		ccp(_bounds.origin.x + _bounds.size.width, _bounds.origin.y + _bounds.size.height),
		ccp(_bounds.origin.x + _bounds.size.width, _bounds.origin.y),
	};
    glLineWidth(4.0f);
	ccDrawPoly(vertices, 4, YES);
    glLineWidth(1.0f);
#endif
}

#pragma mark - update frame

/** Tick function. If overriding class, make sure to call [super update] in your subclass. */
-(void)update:(CCTime)delta{
    // return if not animating
    if(_currentAnimMode == FxSpriteAnimModeStopped) return;
    
    // apply current frame time to all layers
    NSInteger layerIndex = 0;
    _bounds = CGRectMake(0, 0, 1, 1);
    for (FxSprite* s in _layers) {
        [s applyAnimSprite:self
             asLayerIndex:layerIndex
                  atFrame:(_currentAnimation.fps * _animationTime)
                wrapAround:_wrapEndOfLoop];
        if(layerIndex){
            // calculate bounding box
            _bounds = CGRectUnion(_bounds, s.boundingBox);
        } else {
            _bounds = s.boundingBox;
        }
        layerIndex++;
    }
    
    _contentSize = _bounds.size;
    
    // process frame comments
    NSInteger prevFrame = _frameNumber;
    _frameNumber = floorf(_currentAnimation.fps * _animationTime);
    if(_frameNumber != prevFrame){
        NSString* fkey = [NSString stringWithFormat:@"%d", _frameNumber];
        NSString* fcomm = [_currentAnimation.frameComments objectForKey:fkey];
        if(fcomm && _onFrameComment){
            _onFrameComment(self, fcomm);
        }
        if(_onFrameEntered) _onFrameEntered(self);
    }
    
    // advance time
    _animationTime += delta * _animationTimeDilation;
    CGFloat frameTime = _currentAnimation.fps * _animationTime;
    
    // apply current anim mode to time
    NSRange sequenceRange = [_currentAnimation sequenceRange:_currentSequence];
    BOOL animEnded = (frameTime >= sequenceRange.length);
    if(animEnded){
        if(_currentAnimMode == FxSpriteAnimModePlayOnce){
            // finished 1 shot anim
            _currentAnimMode = FXSPRITE_STOPPED;
            if(_onAnimationFinished) _onAnimationFinished(self);
        } else if(_currentAnimMode == FxSpriteAnimModeLoop){
            // restart anim
            _animationTime = 0;
            _frameNumber = -1;
            // finished loop
            if(_onAnimationLoopFinished) _onAnimationLoopFinished(self);
        } else if(_currentAnimMode == FxSpriteAnimModeRepeat){
            _repeatCount--;
            if(_repeatCount <= 0){
                _currentAnimMode = FXSPRITE_STOPPED;
                if(_onAnimationFinished) _onAnimationFinished(self);
            } else {
                // restart anim
                _animationTime = 0;
                _frameNumber = -1;
                // finished one loop
                if(_onAnimationLoopFinished) _onAnimationLoopFinished(self);
            }
        }
    }
}

#pragma mark - anim routines

-(void)stopAnim {
    _currentAnimMode = FxSpriteAnimModeStopped;
}

-(void)repeatAnim:(NSString *)animPath times:(NSInteger)count{
    if(![self prepareForAnimWithPath:animPath]) return;
    
    _animationTime = 0.0;
    _frameNumber = -1;
    _repeatCount = count;
    _currentAnimMode = FxSpriteAnimModeRepeat;
}

-(void)loopAnim:(NSString *)animPath{
    if(![self prepareForAnimWithPath:animPath]) return;
    
    _animationTime = 0.0;
    _frameNumber = -1;
    _currentAnimMode = FxSpriteAnimModeLoop;
}

-(void)playAnim:(NSString *)animPath{
    if(![self prepareForAnimWithPath:animPath]) return;
    
    _animationTime = 0.0;
    _frameNumber = -1;
    _currentAnimMode = FxSpriteAnimModePlayOnce;
}

-(void)gotoAndStop:(NSString *)animPath frameOffset:(NSInteger)f{
    if(![self prepareForAnimWithPath:animPath]) return;

    _animationTime = (CGFloat)f / _currentAnimation.fps;
    _repeatCount = 0;
    _currentAnimMode = FxSpriteAnimModePlayOnce;
    _frameNumber = -1;
    
    [self update:0];
    
    _currentAnimMode = FxSpriteAnimModeStopped;
}

-(void)gotoAndStop:(NSString *)animPath {
    [self gotoAndStop:animPath frameOffset:0];
}

#pragma mark - access layer

-(FxSprite*)layerByName:(NSString *)name {
    NSNumber* index = [_currentAnimation.layerNameNumber objectForKey:name];
    NSInteger intIndex;
    if(!index || ((intIndex = [index integerValue]) >= _layers.count)) return nil;
    return [_layers objectAtIndex:intIndex];
}

-(void)overrideLayer:(NSString*)layerName withSymbol:(NSString*)symb {
    [_layerOverrides setObject:[symb copy] forKey:layerName];
}

-(void)clearOverrides {
    [_layerOverrides removeAllObjects];
}

#pragma mark - anim setup

-(BOOL)prepareForAnimWithPath:(NSString *)animPath{
    NSArray* components = [animPath componentsSeparatedByString:@"/"];
    if(components.count != 2){
        NSLog(@"WARNING playAnim:animPath should be of the form \"animFileName/animName\", e.g. [sprite playAnim:@\"man/run\"];");
        return FALSE;
    }
    
    FxAnimation* anim = [FxAnimation animationNamed:[components objectAtIndex:0]];
    if(!anim){
        NSLog(@"WARNING FxSprite playAnim:animPath could not load animation %@", animPath);
        return FALSE;
    }
    
    // if animation changed, refresh layers
    if(_currentAnimation != anim){
        // adjust the number of layers
        NSInteger layerNumber = 0;
        for (NSString* layerName in anim.layerNames) {
            FxSprite* s = nil;
            // layer already exists
            if(layerNumber < _layers.count){
                s = [_layers objectAtIndex:layerNumber];
                // add new layer
            } else {
                s = [FxSprite node];
                [self addChild:s z:1000 - layerNumber];
                [_layers addObject:s];
            }
            //s.vertexZ = -layerNumber;
            s.name = layerName;
            layerNumber++;
        }
        // remove leftovers
        while (layerNumber < _layers.count) {
            [self removeChild:[_layers lastObject]];
            [_layers removeLastObject];
        }
    }
    _currentAnimation = anim;
    
    NSString* seqName = [components objectAtIndex:1];
    if(![anim.sequenceRanges objectForKey:seqName]){
        NSLog(@"WARNING FxSprite playAnim:animPath could not find sequence %@", animPath);
        return FALSE;
    }
    _currentSequence = [seqName copy];

    // reapply colors
    self.opacity = self.opacity;
    self.color = self.color;
    
    return TRUE;
}

#pragma mark - bounds

/** box that encloses all of this sprite's animated layers, in parent's coordinate system. */
-(CGRect)boundingBox{
    return CGRectApplyAffineTransform(_bounds, [self nodeToParentTransform]);
}

#pragma mark - retina/nonretina flag

static BOOL _texturesAreHalfSized = false;

+(BOOL)texturesAreHalfSized {
    return _texturesAreHalfSized;
}

+(void)setTexturesAreHalfSized:(BOOL)hs {
    _texturesAreHalfSized = hs;
}


@end
