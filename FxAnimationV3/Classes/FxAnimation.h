#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

struct AnimFrame {
    NSInteger f;
    CGFloat x, y;
    CGFloat tx, ty;
    CGFloat sx, sy;
    CGFloat rx, ry;
    CGFloat tint[8];
    NSInteger m;
    BOOL h;
} typedef AnimFrame;

@interface FxAnimation : NSObject {
    NSMutableDictionary* _layerNameNumber;
    NSMutableArray* _layerNames;
    NSMutableArray* _layerSymbols;
    NSMutableDictionary* _frameLabels;
    NSMutableDictionary* _frameComments;
    NSMutableDictionary* _sequenceRanges;
    NSMutableArray* _animationTracks;
}

@property (readonly) NSString* name;
@property (readonly) NSInteger fps;
@property (readonly) NSDictionary* layerNameNumber;
@property (readonly) NSArray* layerNames;
@property (readonly) NSArray* layerSymbols;
@property (readonly) NSDictionary* frameLabels;
@property (readonly) NSDictionary* sequenceRanges;
@property (readonly) NSDictionary* frameComments;
@property (readonly) NSArray* animationTracks;

-(id)initWithName:(NSString*)name;
-(NSRange)sequenceRange:(NSString*)sequenceName;

+(FxAnimation*)animationNamed:(NSString*)name;

/** These contain NSValues with CGRects that represent Flash's symbol offset rectangles.
Use +(CGRect)offsetForSymbol:(NSString*)symbolName atFrame:(NSInteger)frameNumber;
and +(void)setOffset:(CGRect)offset forSymbol:(NSString*)symbolName atFrame:(NSInteger)frameNumber;
to adjust globally.*/
+(NSMutableDictionary*)symbolOffsets;
+(CGRect)offsetForSymbol:(NSString*)symbolName atFrame:(NSInteger)frameNumber;
+(void)setOffset:(CGRect)offset forSymbol:(NSString*)symbolName atFrame:(NSInteger)frameNumber;

/** clears cached FxAnimations */
+(void)emptyCache;

@end
