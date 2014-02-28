#import "FxAnimation.h"
#import "JSONKit.h"

@implementation FxAnimation

@synthesize layerNameNumber=_layerNameNumber, layerNames=_layerNames, layerSymbols=_layerSymbols, frameComments=_frameComments, frameLabels=_frameLabels, sequenceRanges=_sequenceRanges, animationTracks=_animationTracks;

-(id)initWithName:(NSString*)name {
    self = [super init];
    
    NSString* bundlePath = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    NSDictionary* obj = [[JSONDecoder decoder] objectWithData:[NSData dataWithContentsOfFile:bundlePath]];
    if(!obj) return nil;
    
    _name = [name copy];
    _layerNameNumber = [[NSMutableDictionary alloc] init];
    _layerNames = [[NSMutableArray alloc] init];
    _layerSymbols = [[NSMutableArray alloc] init];
    _frameLabels = [[NSMutableDictionary alloc] init];
    _frameComments = [[NSMutableDictionary alloc] init];
    _sequenceRanges = [[NSMutableDictionary alloc] init];
    _animationTracks = [[NSMutableArray alloc] init];
    //NSLog(@"!!! %@", obj);

    // symbolOffsets is static to this class
    if(!_symbolOffsets){
        _symbolOffsets = [[NSMutableDictionary alloc] init];
    }
    
    // parse basic info
    // fps
    _fps = [[obj objectForKey:@"fps"] integerValue];
    
    // layer names and symbols
    for (NSDictionary* dic in [obj objectForKey:@"layerSymbols"]) {
        [_layerNameNumber setObject:[NSNumber numberWithInt:_layerNameNumber.count] forKey:[dic objectForKey:@"layer"]];
        [_layerNames addObject:[dic objectForKey:@"layer"]];
        [_layerSymbols addObject:[[dic objectForKey:@"symbol"] copy]];
    }
    
    // symbol offsets
    for (NSDictionary* dic in [obj objectForKey:@"symbols"]) {
        NSArray* frames = [dic objectForKey:@"frames"];
        NSMutableArray* offsets = [NSMutableArray arrayWithCapacity:frames.count];
        CGRect symbolOffset;
        for (NSArray* offs in frames) {
            symbolOffset = CGRectMake([[offs objectAtIndex:0] floatValue], (-1) * [[offs objectAtIndex:1] floatValue],
                                             [[offs objectAtIndex:2] floatValue], [[offs objectAtIndex:3] floatValue]);
            NSValue* val = [NSValue value:&symbolOffset withObjCType:@encode(CGRect)];
            [offsets addObject:val];
        }
        [_symbolOffsets setObject:offsets forKey:[dic objectForKey:@"name"]];
    }
    
    // frame labels
    for (NSDictionary* dic in [obj objectForKey:@"frameLabels"]) {
        [_frameLabels setObject:[NSNumber numberWithInteger:[[dic objectForKey:@"f"] integerValue]]
                         forKey:[dic objectForKey:@"l"]];
        
    }
    
    // extract ranges
    NSInteger totalFrames = ((NSArray*)[[obj objectForKey:@"layerAnims"] objectAtIndex:0]).count;
    NSArray* seqNames = _frameLabels.allKeys;
    for(NSString* seqName in seqNames) {
        NSInteger startFrame = [[_frameLabels objectForKey:seqName] integerValue];
        BOOL found = false;
        for (NSInteger f = startFrame; f < totalFrames; f++) {
            // find a sequence that starts with f - this signals the end
            for(NSString* sn in seqNames) {
                NSInteger sf = [[_frameLabels objectForKey:sn] integerValue];
                if(sf == f && ![sn isEqualToString:seqName] && !found){
                    found = true;
                    NSRange rng = NSMakeRange(startFrame, sf - startFrame);
                    [_sequenceRanges setObject:[NSValue value:&rng withObjCType:@encode(NSRange)]
                                        forKey:seqName];
                    continue;
                }
            }
        }
        if(!found){
            NSRange rng = NSMakeRange(startFrame, totalFrames - startFrame);
            [_sequenceRanges setObject:[NSValue value:&rng withObjCType:@encode(NSRange)]
                                forKey:seqName];
        }
    }
    
    // frame comments - number -> comment
    for (NSDictionary* dic in [obj objectForKey:@"frameComments"]) {
        [_frameComments setObject:[dic objectForKey:@"c"]
                         forKey:[[dic objectForKey:@"f"] description]];
    }
    
    // create animation tracks for each layer
    NSInteger layerNum = 0;
    for (NSArray* layerFrames in [obj objectForKey:@"layerAnims"]) {
        NSMutableArray* track = [NSMutableArray array];
        for (NSDictionary* dic in layerFrames) {
            AnimFrame frame;
            frame.f = [[dic objectForKey:@"f"] integerValue];
            frame.x = [[dic objectForKey:@"x"] floatValue];
            frame.y = [[dic objectForKey:@"y"] floatValue];
            frame.tx = [[dic objectForKey:@"tx"] floatValue];
            frame.ty = [[dic objectForKey:@"ty"] floatValue];
            frame.sx = [[dic objectForKey:@"sx"] floatValue];
            frame.sy = [[dic objectForKey:@"sy"] floatValue];
            frame.rx = [[dic objectForKey:@"rx"] floatValue];
            frame.ry = [[dic objectForKey:@"ry"] floatValue];
            frame.m = [[dic objectForKey:@"m"] integerValue];
            frame.h = ([dic objectForKey:@"h"] != nil);
            
            NSString* ctx = [dic objectForKey:@"c"];
            if(ctx){
                NSInteger i = 0;
                NSArray* ctxs = [ctx componentsSeparatedByString:@","];
                for (NSString* n in ctxs) {
                    if(i < 4){
                        frame.tint[i] = [n floatValue] * 0.01;
                    } else {
                        frame.tint[i] = [n floatValue] / 255.0;
                    }
                    i++;
                }
            } else {
                frame.tint[0] = frame.tint[1] = frame.tint[2] = 0.0;
                frame.tint[3] = frame.tint[4] = frame.tint[5] = frame.tint[6] = frame.tint[6] = 0.0;
            }
            
            [track addObject:[NSValue valueWithBytes:&frame objCType:@encode(AnimFrame)]];
        }
        [_animationTracks addObject:track];
        layerNum++;
    }
    
    return self;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"FxAnimation \"%@\":\n\
fps: %d\n\
layerNameNumber: %@\n\
layerSymbols: %@\n\
symbolOffsets: %@\n\
frameLabels: %@\n\
frameComments: %@\n\
sequenceRanges: %@\n\
animationTracks: %@\n", _name, _fps, _layerNameNumber, _layerSymbols, _symbolOffsets, _frameLabels, _frameComments, _sequenceRanges, _animationTracks];
}

-(void)dealloc{
}

#pragma mark - animation

// returns range of sequence
-(NSRange)sequenceRange:(NSString*)sequenceName{
    NSRange range = NSMakeRange(0, 0);
    NSValue* val = [_sequenceRanges objectForKey:sequenceName];
    if(val){
        [val getValue:&range];
    }
    return range;
}

#pragma mark - cached animations access

static NSMutableDictionary* _animationCache = nil;
static NSMutableDictionary* _symbolOffsets = nil;

+(NSMutableDictionary*)symbolOffsets {
    if(!_symbolOffsets){
        _symbolOffsets = [[NSMutableDictionary alloc] init];
    }
    return _symbolOffsets;
}

+(CGRect)offsetForSymbol:(NSString*)symbolName atFrame:(NSInteger)frameNumber{
    NSArray* offsets = [_symbolOffsets objectForKey:symbolName];
    if(!offsets) {
        NSLog(@"ERROR: Symbol %@ not found in FxAnimation's symbolOffsets.", symbolName);
        return CGRectZero;
    }
    if(frameNumber < 0 || frameNumber > offsets.count - 1){
        NSLog(@"ERROR: Symbol %@ only has %d frames", symbolName, offsets.count);
        return CGRectZero;
    }
    CGRect symbolOffset;
    NSValue* offs = [offsets objectAtIndex:frameNumber];
    [offs getValue:&symbolOffset];
    return symbolOffset;
}

+(void)setOffset:(CGRect)offset forSymbol:(NSString*)symbolName atFrame:(NSInteger)frameNumber{
    NSMutableArray* offsets = [_symbolOffsets objectForKey:symbolName];
    if(!offsets) {
        NSLog(@"ERROR: Symbol %@ not found in FxAnimation's symbolOffsets.", symbolName);
        return;
    }
    if(frameNumber < 0 || frameNumber > offsets.count - 1){
        NSLog(@"ERROR: Symbol %@ only has %d frames", symbolName, offsets.count);
        return;
    }
    NSValue* val = [NSValue value:&offset withObjCType:@encode(CGRect)];
    [offsets setObject:val atIndexedSubscript:frameNumber];
}

+(FxAnimation*)animationNamed:(NSString*)name {
    // find in cache
    FxAnimation* ret = nil;
    if(_animationCache){
        ret = [_animationCache objectForKey:name];
        if (ret) {
            return ret;
        } else {
            ret = [[FxAnimation alloc] initWithName:name];
            if(ret) {
                [_animationCache setObject:ret forKey:name];
            }
        }
    } else {
        ret = [[FxAnimation alloc] initWithName:name];
        _animationCache = [[NSMutableDictionary alloc] init];
        if(ret) {
            [_animationCache setObject:ret forKey:name];
        }
    }
    return ret;
}

+(void)emptyCache {
    [_animationCache removeAllObjects];
    [_symbolOffsets removeAllObjects];
}


@end
