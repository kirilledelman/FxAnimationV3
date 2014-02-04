FxAnimationV3
=============

A simple library to export and animate Flash symbols in iOS / Cocos2d V3, with included example.

For Cocos2d 2.x branch, see FxAnimation repo: https://github.com/kirilledelman/FxAnimation

Workflow:
* Create your animations in Flash as MovieClips with animated layers containing Graphic symbols. 
* Export animations as JSON + frame PNGs using included JSFL script.
* Convert PNGs into sprite sheets (use your own tools, I use http://www.codeandweb.com/texturepacker)
* Include animation JSON file(s) and sprite sheets in app bundle.
* Load textures, run complex multilayer animations on sprites using simple commands.

Features:
* Supports MotionObject animations in Flash, including skew and color transforms.
* Supported Graphic symbol's current frame/looping mode from Flash.
* In cocos2d animations can be looped, played once, repeated n times, or gotoandstop'd.
* Frame labels used to separate multiple sequences in a single animation.
* Frame comments can be used as event triggers.
* Animation speed can be adjusted on the fly, transforms are tweened smoothly between frames.
* Support for retina/non-retina sprite sizing.
* Lightweight and fast.

Inspired by animation done by developers of Klei's Don't Starve: http://kleientertainment.com/games/dont-starve/

If you make something cool with this, please let me know.

JSFL Notes
==========

HOW TO USE:   
Make a MovieClip with a separate layer for each body part,  
Each body part has to be a Graphic with one or more frames.  
Make an empty layer, used only for frame labels, which designate the beginning of a sequence(s).

To export, either go to the top level of the document and select one or more movie clips on stage,
or go into the timeline of a movie clip you wish to export and run this script.

You should see the JSON file printed out on output console, and written to disk.  
PNGs for each frame of each symbol will also be written out.  
The JSON file should be included in the app's bundle.  
The PNGs have to be converted into a sprite sheet + plist, and also included in app's bundle. I use http://www.codeandweb.com/texturepacker.  
See HelloWorldLayer.m for loading textures and playing animation.

Supported:
* Motion, scale, rotate, skew animation (MotionObject).
* Tint, Advanced Tint, Alpha, Brightness animation.
* Graphic symbol's loop mode / current frame.
* One or more sequences per MovieClip, using frame labels.

Notes:
* I recommend using meaningful names for layers and symbols - makes it easier to debug.
* Animated color transformations are tweened linearly, disregarding easing
* Each layer of the exported movie clip represents a single cocos2d sprite, to be animated.
* Bones are not supported.
* Frames can also have comments, which can be used programmatically as event triggers with FxAnimatedSprite.onFrameComment.
* Flash file FPS controls global animation speed
* When an animation is played by FxAnimatedSprite, it will smoothly tween in between frames, and snap to static frames
* It's possible to hide a symbol by having blank frames, but first frame of timeline can not be blank, or layer won't be exported.
* Hidden or guide layers are not exported.
* All symbols inside the MovieClip being exported must be Graphic
* Graphic's current frame is exported with the animation, respecting loop mode (single frame/loop/play once).

DISCLAIMER:  
Only tested with Flash CS6, on Mac only.  
Use at own risk. This should leave your Flash file unmodified, but I do recommend backups.  
