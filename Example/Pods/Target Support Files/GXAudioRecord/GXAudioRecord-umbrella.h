#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AQPlayerManager.h"
#import "AQRecorderManager.h"
#import "AQUnitTools.h"
#import "GGXAudioConvertor.h"
#import "GGXAudioQueueHeader.h"
#import "GGXFileManeger.h"
#import "JHAudioRecorder.h"
#import "lame.h"
#import "MusicControl.h"
#import "MusicModel.h"
#import "ParsingAudioHander.h"

FOUNDATION_EXPORT double GXAudioRecordVersionNumber;
FOUNDATION_EXPORT const unsigned char GXAudioRecordVersionString[];

