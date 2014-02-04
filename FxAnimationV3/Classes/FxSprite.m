#import "CCTexture_Private.h"
#import "FxSprite.h"
#import "FxAnimatedSprite.h"

@interface CCSprite ()
-(void)setTextureCoords:(CGRect)rect;
@end

@implementation FxSprite

static BOOL _shaderLoaded = false;
static GLint _uniformTintPercent = 0;
static GLint _uniformTintOffset = 0;

-(id)init {
    self = [super init];
    
    if(!_shaderLoaded){
        [FxSprite loadShader];
    }
    
    self.tintPercent = ccc4f(1.0, 1.0, 1.0, 1.0);
    self.tintOffset = ccc4f(0, 0, 0, 0);
    _shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:@"ShaderPositionTextureTint"];
    
#if CC_SPRITE_DEBUG_DRAW == 1
    CCLabelTTF* origin = [CCLabelTTF labelWithString:@"x" fontName:@"Courier" fontSize:12];
    origin.anchorPoint = ccp(0.5, 0.5);
    origin.position = ccp(0, 0);
    [self addChild:origin z:10000];
#endif
    
    return self;
}

-(void)dealloc{
}

#pragma mark - bounds

-(CGRect) boundingBox {
	CGRect rect = CGRectMake(_quad.bl.vertices.x, _quad.bl.vertices.y, _contentSize.width, _contentSize.height);
	return CGRectApplyAffineTransform(rect, [self nodeToParentTransform]);
}

#pragma mark - animation

-(void)setSpriteFrameName:(NSString*)spf withOffsetRect:(CGRect)offsetRect{
    CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spf];
    
    self.scale = 1.0 / [UIScreen mainScreen].scale;
    
    // code below is straight from setDisplayRect, adjusted so sprite rectangle is at 0,0
    // not centered as default implementation
    
    _unflippedOffsetPositionFromCenter = frame.offset;
    CGPoint extraOffsets = offsetRect.origin;

	CCTexture *newTexture = [frame texture];
    
	// update texture before updating texture rect
	if ( newTexture.name != _texture.name )
		[self setTexture: newTexture];
    
	// update rect
	_rectRotated = frame.rotated;

    CGRect rectInPixels = CC_RECT_SCALE(frame.rect, frame.texture.contentScale);
    if([FxAnimatedSprite texturesAreHalfSized]){
        CGRect dblRect = CGRectMake(rectInPixels.origin.x * 2,
                                    rectInPixels.origin.y * 2,
                                    rectInPixels.size.width * 2,
                                    rectInPixels.size.height * 2);
        [self setContentSize:dblRect.size];
        //[self setVertexRect:dblRect];
        _rect = dblRect;
    } else {
        [self setContentSize:rectInPixels.size];
        _rect = rectInPixels;
    }
    // generates warning because CCSprite header doesn't have this declared
    [self setTextureCoords:frame.rect];
    
    CGPoint relativeOffset = _unflippedOffsetPositionFromCenter;
    
    // issue #732
    if( _flipX )
        relativeOffset.x = -relativeOffset.x;
    if( _flipY )
        relativeOffset.y = -relativeOffset.y;
    
    
    _offsetPosition.x = extraOffsets.x;
    _offsetPosition.y = extraOffsets.y - _rect.size.height;
    
    // rendering using batch node
    if( _batchNode ) {
        // update _dirty, don't update _recursiveDirty
        _dirty = YES;
    }
    
    // self rendering
    else
    {
        // Atlas: Vertex
        float x1 = _offsetPosition.x;
        float y1 = _offsetPosition.y;
        float x2 = x1 + _rect.size.width;
        float y2 = y1 + _rect.size.height;
        
        // Don't update Z.
        _quad.bl.vertices = (ccVertex3F) { x1, y1, 0 };
        _quad.br.vertices = (ccVertex3F) { x2, y1, 0 };
        _quad.tl.vertices = (ccVertex3F) { x1, y2, 0 };
        _quad.tr.vertices = (ccVertex3F) { x2, y2, 0 };
    }
}

// modified to apply tint color to shader
-(void) draw {
	CC_PROFILER_START_CATEGORY(kCCProfilerCategorySprite, @"CCSprite - draw");
	NSAssert(!_batchNode, @"If CCSprite is being rendered by CCSpriteBatchNode, CCSprite#draw SHOULD NOT be called");
	CC_NODE_DRAW_SETUP();
    
	ccGLBlendFunc( _blendFunc.src, _blendFunc.dst );
	ccGLBindTexture2D( [_texture name] );
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_PosColorTex );

    // apply shader uniforms
    static ccColor4F _lastShaderTintPerc = { 0, 0, 0, 0 };
    static ccColor4F _lastShaderTintOffs = { 0, 0, 0, 0 };
    
    if(!ccc4FEqual(_lastShaderTintPerc, _tintPercent)){
        [_shaderProgram setUniformLocation:_uniformTintPercent with4fv:&_tintPercent count:1];
        _lastShaderTintPerc = _tintPercent;
    }
    if(!ccc4FEqual(_lastShaderTintOffs, _tintOffset)){
        [_shaderProgram setUniformLocation:_uniformTintOffset with4fv:&_tintOffset count:1];
        _lastShaderTintOffs = _tintOffset;
    }
    
    glDisable(GL_CULL_FACE);

    
#define kQuadSize sizeof(_quad.bl)
	long offset = (long)&_quad;
	// vertex
	NSInteger diff = offsetof( ccV3F_C4B_T2F, vertices);
	glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, kQuadSize, (void*) (offset + diff));
	// texCoods
	diff = offsetof( ccV3F_C4B_T2F, texCoords);
	glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, kQuadSize, (void*)(offset + diff));
	// color
	diff = offsetof( ccV3F_C4B_T2F, colors);
	glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, kQuadSize, (void*)(offset + diff));
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
	CHECK_GL_ERROR_DEBUG();
    
#if CC_SPRITE_DEBUG_DRAW == 1
	// draw bounding box
	CGPoint vertices[4]={
		ccp(_quad.tl.vertices.x,_quad.tl.vertices.y),
		ccp(_quad.bl.vertices.x,_quad.bl.vertices.y),
		ccp(_quad.br.vertices.x,_quad.br.vertices.y),
		ccp(_quad.tr.vertices.x,_quad.tr.vertices.y),
	};
	ccDrawPoly(vertices, 4, YES);
#elif CC_SPRITE_DEBUG_DRAW == 2
	// draw texture box
	CGSize s = self.textureRect.size;
	CGPoint offsetPix = self.offsetPosition;
	CGPoint vertices[4] = {
		ccp(offsetPix.x,offsetPix.y), ccp(offsetPix.x+s.width,offsetPix.y),
		ccp(offsetPix.x+s.width,offsetPix.y+s.height), ccp(offsetPix.x,offsetPix.y+s.height)
	};
	ccDrawPoly(vertices, 4, YES);
#endif // CC_SPRITE_DEBUG_DRAW
    
	CC_INCREMENT_GL_DRAWS(1);
	CC_PROFILER_STOP_CATEGORY(kCCProfilerCategorySprite, @"CCSprite - draw");
}

#define LERP(A,B,C) ((A) + ((B) - (A)) * (C))

-(void)applyAnimSprite:(FxAnimatedSprite*)sprite asLayerIndex:(NSInteger)layerIndex atFrame:(CGFloat)time wrapAround:(BOOL)wrapAround {
    FxAnimation* anim = sprite.currentAnimation;
    NSString* seqName = sprite.currentSequence;
    NSString* symbolName = [anim.layerSymbols objectAtIndex:layerIndex];
    NSString* overrideSymbol = [sprite.layerOverrides objectForKey:[anim.layerNames objectAtIndex:layerIndex]];
    if(overrideSymbol) symbolName = overrideSymbol;
    NSRange seqRange = [anim sequenceRange:seqName];
    NSArray* track = [anim.animationTracks objectAtIndex:layerIndex];
    NSInteger sequenceEnd = seqRange.location + seqRange.length - 1;
    
    AnimFrame aframe, bframe;
    
    // frame A
    NSInteger index = MIN(floorf(seqRange.location + time), sequenceEnd);
    NSValue* fval = [track objectAtIndex:index];
    [fval getValue:&aframe];
    
    // frame B
    index = wrapAround ?
                seqRange.location + fmodf(ceilf(time), (CGFloat) seqRange.length) :
                MIN(ceilf(seqRange.location + time), sequenceEnd);
    fval = [track objectAtIndex:index];
    [fval getValue:&bframe];
    
    // hidden frame
    if(aframe.h && _visible) {
        self.visible = false;
    } else if(!aframe.h && !_visible){
        self.visible = true;
    }
    
    // apply frame A's graphic
    NSArray* symbolOffsets = [[FxAnimation symbolOffsets] objectForKey:symbolName];
    NSString* spriteFrameName = symbolOffsets.count == 1 ?
        [NSString stringWithFormat:@"%@.png", symbolName] :
        [NSString stringWithFormat:@"%@%04d.png", symbolName, MIN(symbolOffsets.count, (aframe.f + 1))];
    if(![lastSetFrameName isEqualToString:spriteFrameName]){
        // find offsets
        CGRect symbolOffset;
        NSValue* offs = [symbolOffsets objectAtIndex:aframe.f];
        [offs getValue:&symbolOffset];
        [self setSpriteFrameName:spriteFrameName withOffsetRect:symbolOffset];
        // save
        lastSetFrameName = [spriteFrameName copy];
    }
    
    // determine transition between A and B
    CGFloat transTime;
    if(!aframe.m || (aframe.m != bframe.m)){ // A is static frame, or A and B are part of different tweens
        transTime = 0; // show A
    } else {
        transTime = time - floorf(time); // fractional part of time
    }
    
    // perform interpolation between A and B
    // transform point
    CGFloat tx = LERP(aframe.tx, bframe.tx, transTime);
    CGFloat ty = -LERP(aframe.ty, bframe.ty, transTime);
    CGPoint ap = ccp(tx / self.contentSize.width, ty / self.contentSize.height);
    [self setAnchorPoint:ap];
    
    // coords and scale
    CGFloat x = LERP(aframe.x, bframe.x, transTime);
    CGFloat y = -LERP(aframe.y, bframe.y, transTime);
    CGFloat sx = LERP(aframe.sx, bframe.sx, transTime);
    CGFloat sy = LERP(aframe.sy, bframe.sy, transTime);
    
    // tint
    _tintPercent = ccc4f(LERP(aframe.tint[0], bframe.tint[0], transTime),
                         LERP(aframe.tint[1], bframe.tint[1], transTime),
                         LERP(aframe.tint[2], bframe.tint[2], transTime),
                         LERP(aframe.tint[3], bframe.tint[3], transTime));
    _tintOffset =  ccc4f(LERP(aframe.tint[4], bframe.tint[4], transTime),
                         LERP(aframe.tint[5], bframe.tint[5], transTime),
                         LERP(aframe.tint[6], bframe.tint[6], transTime),
                         LERP(aframe.tint[7], bframe.tint[7], transTime));
    
    // rotation
    CGFloat rx, ry;
    CGFloat arx = aframe.rx, ary = aframe.ry;
    // detect 180 -> -180 flip for x
    if(arx > 90 && bframe.rx < -90){
        arx = bframe.rx - (180 + bframe.rx + 180 - aframe.rx);
    } else if(arx < -90 && bframe.rx > 90){
        arx = bframe.rx + (180 + aframe.rx + 180 - bframe.rx);
    }
    
    // detect 180 -> -180 flip for y
    if(ary > 90 && bframe.ry < -90){
        ary = bframe.ry - (180 + bframe.ry + 180 - aframe.ry);
    } else if(ary < -90 && bframe.ry > 90){
        ary = bframe.ry + (180 + aframe.ry + 180 - bframe.ry);
    }
    
    rx = LERP(arx, bframe.rx, transTime);
    ry = LERP(ary, bframe.ry, transTime);

    // apply
    _scaleX = sx;
    _scaleY = sy;
    _rotationalSkewX = rx;
    _rotationalSkewY = ry;
    _position = ccp(x, y);
	_isTransformDirty = _isInverseDirty = YES;
}

#pragma mark - shader

const GLchar * fxShaderPositionTextureTint = "\n\
#ifdef GL_ES								\n\
precision lowp float;						\n\
#endif										\n\
                                            \n\
varying vec4 v_fragmentColor;				\n\
varying vec2 v_texCoord;					\n\
uniform vec4 u_tintPerc;                    \n\
uniform vec4 u_tintOffs;                    \n\
uniform sampler2D CC_Texture0;				\n\
                                            \n\
void main()									\n\
{											\n\
    vec4 color = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);      \n\
    gl_FragColor = clamp(color * u_tintPerc * u_tintPerc.a + u_tintOffs * color.a,         \n\
                    vec4(0.0, 0.0, 0.0, 0.0), vec4(1.0, 1.0, 1.0, 1.0));    \n\
}											\n\
";

// this shader is needed to support Flash's tinting animation
+(void)loadShader {
    if(!_shaderLoaded){
        CCGLProgram *p = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTextureColor_vert
                                                    fragmentShaderByteArray:fxShaderPositionTextureTint];
        
        [p addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
        [p addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
        [p addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
        
        [p link];
        [p updateUniforms];
        
        _uniformTintPercent = [p uniformLocationForName:@"u_tintPerc"];
        _uniformTintOffset = [p uniformLocationForName:@"u_tintOffs"];
        
        [[CCShaderCache sharedShaderCache] addProgram:p forKey:@"ShaderPositionTextureTint"];
        
        _shaderLoaded = true;
    }
}

@end
