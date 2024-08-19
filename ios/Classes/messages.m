// Copyright (c) 2019 Alibaba Group. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
// Autogenerated from Pigeon (v3.2.9), do not edit directly.
// See also: https://pub.dev/packages/pigeon
#import "messages.h"
#import <Flutter/Flutter.h>

#if !__has_feature(objc_arc)
#error File requires ARC to be enabled.
#endif

static NSDictionary<NSString *, id> *wrapResult(id result, FlutterError *error) {
  NSDictionary *errorDict = (NSDictionary *)[NSNull null];
  if (error) {
    errorDict = @{
        @"code": (error.code ?: [NSNull null]),
        @"message": (error.message ?: [NSNull null]),
        @"details": (error.details ?: [NSNull null]),
        };
  }
  return @{
      @"result": (result ?: [NSNull null]),
      @"error": errorDict,
      };
}
static id GetNullableObject(NSDictionary* dict, id key) {
  id result = dict[key];
  return (result == [NSNull null]) ? nil : result;
}
static id GetNullableObjectAtIndex(NSArray* array, NSInteger key) {
  id result = array[key];
  return (result == [NSNull null]) ? nil : result;
}


@interface FBCommonParams ()
+ (FBCommonParams *)fromMap:(NSDictionary *)dict;
+ (nullable FBCommonParams *)nullableFromMap:(NSDictionary *)dict;
- (NSDictionary *)toMap;
@end

@interface FBStackInfo ()
+ (FBStackInfo *)fromMap:(NSDictionary *)dict;
+ (nullable FBStackInfo *)nullableFromMap:(NSDictionary *)dict;
- (NSDictionary *)toMap;
@end

@interface FBFlutterContainer ()
+ (FBFlutterContainer *)fromMap:(NSDictionary *)dict;
+ (nullable FBFlutterContainer *)nullableFromMap:(NSDictionary *)dict;
- (NSDictionary *)toMap;
@end

@interface FBFlutterPage ()
+ (FBFlutterPage *)fromMap:(NSDictionary *)dict;
+ (nullable FBFlutterPage *)nullableFromMap:(NSDictionary *)dict;
- (NSDictionary *)toMap;
@end

@implementation FBCommonParams
//通用初始化类方法
+ (instancetype)makeWithOpaque:(nullable NSNumber *)opaque
    key:(nullable NSString *)key
    pageName:(nullable NSString *)pageName
    uniqueId:(nullable NSString *)uniqueId
    arguments:(nullable NSDictionary<NSString *, id> *)arguments {
  FBCommonParams* pigeonResult = [[FBCommonParams alloc] init];
  pigeonResult.opaque = opaque;
  pigeonResult.key = key;
  pigeonResult.pageName = pageName;
  pigeonResult.uniqueId = uniqueId;
  pigeonResult.arguments = arguments;
  return pigeonResult;
}

//通过传入map初始化类方法
+ (FBCommonParams *)fromMap:(NSDictionary *)dict {
  FBCommonParams *pigeonResult = [[FBCommonParams alloc] init];
  pigeonResult.opaque = GetNullableObject(dict, @"opaque");
  pigeonResult.key = GetNullableObject(dict, @"key");
  pigeonResult.pageName = GetNullableObject(dict, @"pageName");
  pigeonResult.uniqueId = GetNullableObject(dict, @"uniqueId");
  pigeonResult.arguments = GetNullableObject(dict, @"arguments");
  return pigeonResult;
}

+ (nullable FBCommonParams *)nullableFromMap:(NSDictionary *)dict { return (dict) ? [FBCommonParams fromMap:dict] : nil; }

// 反序列化方法
- (NSDictionary *)toMap {
  return @{
    @"opaque" : (self.opaque ?: [NSNull null]),
    @"key" : (self.key ?: [NSNull null]),
    @"pageName" : (self.pageName ?: [NSNull null]),
    @"uniqueId" : (self.uniqueId ?: [NSNull null]),
    @"arguments" : (self.arguments ?: [NSNull null]),
  };
}

@end


/**
 * FB 栈信息类
 */
@implementation FBStackInfo
// 初始化
+ (instancetype)makeWithIds:(nullable NSArray<NSString *> *)ids
    containers:(nullable NSDictionary<NSString *, FBFlutterContainer *> *)containers {
  FBStackInfo* pigeonResult = [[FBStackInfo alloc] init];
  pigeonResult.ids = ids;
  pigeonResult.containers = containers;
  return pigeonResult;
}

+ (FBStackInfo *)fromMap:(NSDictionary *)dict {
  FBStackInfo *pigeonResult = [[FBStackInfo alloc] init];
  pigeonResult.ids = GetNullableObject(dict, @"ids");
  pigeonResult.containers = GetNullableObject(dict, @"containers");
  return pigeonResult;
}
+ (nullable FBStackInfo *)nullableFromMap:(NSDictionary *)dict { return (dict) ? [FBStackInfo fromMap:dict] : nil; }
- (NSDictionary *)toMap {
  return @{
    @"ids" : (self.ids ?: [NSNull null]),
    @"containers" : (self.containers ?: [NSNull null]),
  };
}
@end

/**
 * FB flutter 容器类
 */
@implementation FBFlutterContainer
+ (instancetype)makeWithPages:(nullable NSArray<FBFlutterPage *> *)pages {
  FBFlutterContainer* pigeonResult = [[FBFlutterContainer alloc] init];
  pigeonResult.pages = pages;
  return pigeonResult;
}
+ (FBFlutterContainer *)fromMap:(NSDictionary *)dict {
  FBFlutterContainer *pigeonResult = [[FBFlutterContainer alloc] init];
  pigeonResult.pages = GetNullableObject(dict, @"pages");
  return pigeonResult;
}
+ (nullable FBFlutterContainer *)nullableFromMap:(NSDictionary *)dict { return (dict) ? [FBFlutterContainer fromMap:dict] : nil; }
- (NSDictionary *)toMap {
  return @{
    @"pages" : (self.pages ?: [NSNull null]),
  };
}
@end

/**
 * flutter 页面page类
 */
@implementation FBFlutterPage
+ (instancetype)makeWithWithContainer:(nullable NSNumber *)withContainer
    pageName:(nullable NSString *)pageName
    uniqueId:(nullable NSString *)uniqueId
    arguments:(nullable NSDictionary<NSString *, id> *)arguments {
  FBFlutterPage* pigeonResult = [[FBFlutterPage alloc] init];
  pigeonResult.withContainer = withContainer;
  pigeonResult.pageName = pageName;
  pigeonResult.uniqueId = uniqueId;
  pigeonResult.arguments = arguments;
  return pigeonResult;
}
+ (FBFlutterPage *)fromMap:(NSDictionary *)dict {
  FBFlutterPage *pigeonResult = [[FBFlutterPage alloc] init];
  pigeonResult.withContainer = GetNullableObject(dict, @"withContainer");
  pigeonResult.pageName = GetNullableObject(dict, @"pageName");
  pigeonResult.uniqueId = GetNullableObject(dict, @"uniqueId");
  pigeonResult.arguments = GetNullableObject(dict, @"arguments");
  return pigeonResult;
}
+ (nullable FBFlutterPage *)nullableFromMap:(NSDictionary *)dict { return (dict) ? [FBFlutterPage fromMap:dict] : nil; }
- (NSDictionary *)toMap {
  return @{
    @"withContainer" : (self.withContainer ?: [NSNull null]),
    @"pageName" : (self.pageName ?: [NSNull null]),
    @"uniqueId" : (self.uniqueId ?: [NSNull null]),
    @"arguments" : (self.arguments ?: [NSNull null]),
  };
}
@end


// FB Native Router 数据读取器
@interface FBNativeRouterApiCodecReader : FlutterStandardReader
@end
@implementation FBNativeRouterApiCodecReader
- (nullable id)readValueOfType:(UInt8)type 
{
  switch (type) {
    case 128:     
      return [FBCommonParams fromMap:[self readValue]];
    
    case 129:     
      return [FBFlutterContainer fromMap:[self readValue]];
    
    case 130:     
      return [FBFlutterPage fromMap:[self readValue]];
    
    case 131:     
      return [FBStackInfo fromMap:[self readValue]];
    
    default:    
      return [super readValueOfType:type];
    
  }
}
@end

// 数据写入器
@interface FBNativeRouterApiCodecWriter : FlutterStandardWriter
@end
@implementation FBNativeRouterApiCodecWriter
- (void)writeValue:(id)value 
{
  if ([value isKindOfClass:[FBCommonParams class]]) {
    [self writeByte:128];
    [self writeValue:[value toMap]];
  } else 
  if ([value isKindOfClass:[FBFlutterContainer class]]) {
    [self writeByte:129];
    [self writeValue:[value toMap]];
  } else 
  if ([value isKindOfClass:[FBFlutterPage class]]) {
    [self writeByte:130];
    [self writeValue:[value toMap]];
  } else 
  if ([value isKindOfClass:[FBStackInfo class]]) {
    [self writeByte:131];
    [self writeValue:[value toMap]];
  } else 
{
    [super writeValue:value];
  }
}
@end

@interface FBNativeRouterApiCodecReaderWriter : FlutterStandardReaderWriter
@end
@implementation FBNativeRouterApiCodecReaderWriter
//数据写入器
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
  return [[FBNativeRouterApiCodecWriter alloc] initWithData:data];
}
//数据读取器
- (FlutterStandardReader *)readerWithData:(NSData *)data {
  return [[FBNativeRouterApiCodecReader alloc] initWithData:data];
}
@end

/**
 * Flutter 编解码器初始化
 */
NSObject<FlutterMessageCodec> *FBNativeRouterApiGetCodec() {
  static dispatch_once_t sPred = 0;
  static FlutterStandardMessageCodec *sSharedObject = nil;
  dispatch_once(&sPred, ^{
    FBNativeRouterApiCodecReaderWriter *readerWriter = [[FBNativeRouterApiCodecReaderWriter alloc] init];
    sSharedObject = [FlutterStandardMessageCodec codecWithReaderWriter:readerWriter];
  });
  return sSharedObject;
}


/**
 * api 传入的是plugin，是因为plugin实现了FBNativeRouterApi协议
 * flutter 侧送的channel事件，native侧接收处理
 * binaryMessenger 是flutter engin 里取的
 */
void FBNativeRouterApiSetup(id<FlutterBinaryMessenger> binaryMessenger, NSObject<FBNativeRouterApi> *api) {
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:@"dev.flutter.pigeon.NativeRouterApi.pushNativeRoute"
        binaryMessenger:binaryMessenger
        codec:FBNativeRouterApiGetCodec()        ];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(pushNativeRouteParam:error:)], @"FBNativeRouterApi api (%@) doesn't respond to @selector(pushNativeRouteParam:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        // 接收消息
        NSArray *args = message;
        FBCommonParams *arg_param = GetNullableObjectAtIndex(args, 0);
        FlutterError *error;
        [api pushNativeRouteParam:arg_param error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:@"dev.flutter.pigeon.NativeRouterApi.pushFlutterRoute"
        binaryMessenger:binaryMessenger
        codec:FBNativeRouterApiGetCodec()        ];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(pushFlutterRouteParam:error:)], @"FBNativeRouterApi api (%@) doesn't respond to @selector(pushFlutterRouteParam:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray *args = message;
        FBCommonParams *arg_param = GetNullableObjectAtIndex(args, 0);
        FlutterError *error;
        [api pushFlutterRouteParam:arg_param error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:@"dev.flutter.pigeon.NativeRouterApi.popRoute"
        binaryMessenger:binaryMessenger
        codec:FBNativeRouterApiGetCodec()        ];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(popRouteParam:completion:)], @"FBNativeRouterApi api (%@) doesn't respond to @selector(popRouteParam:completion:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray *args = message;
        FBCommonParams *arg_param = GetNullableObjectAtIndex(args, 0);
        [api popRouteParam:arg_param completion:^(FlutterError *_Nullable error) {
          callback(wrapResult(nil, error));
        }];
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:@"dev.flutter.pigeon.NativeRouterApi.getStackFromHost"
        binaryMessenger:binaryMessenger
        codec:FBNativeRouterApiGetCodec()        ];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(getStackFromHostWithError:)], @"FBNativeRouterApi api (%@) doesn't respond to @selector(getStackFromHostWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FBStackInfo *output = [api getStackFromHostWithError:&error];
        callback(wrapResult(output, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:@"dev.flutter.pigeon.NativeRouterApi.saveStackToHost"
        binaryMessenger:binaryMessenger
        codec:FBNativeRouterApiGetCodec()        ];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(saveStackToHostStack:error:)], @"FBNativeRouterApi api (%@) doesn't respond to @selector(saveStackToHostStack:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray *args = message;
        FBStackInfo *arg_stack = GetNullableObjectAtIndex(args, 0);
        FlutterError *error;
        [api saveStackToHostStack:arg_stack error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:@"dev.flutter.pigeon.NativeRouterApi.sendEventToNative"
        binaryMessenger:binaryMessenger
        codec:FBNativeRouterApiGetCodec()        ];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(sendEventToNativeParams:error:)], @"FBNativeRouterApi api (%@) doesn't respond to @selector(sendEventToNativeParams:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray *args = message;
        FBCommonParams *arg_params = GetNullableObjectAtIndex(args, 0);
        FlutterError *error;
        [api sendEventToNativeParams:arg_params error:&error];
        callback(wrapResult(nil, error));
      }];
    }
    else {
      [channel setMessageHandler:nil];
    }
  }
}

//FB Flutter Router 解码器
@interface FBFlutterRouterApiCodecReader : FlutterStandardReader
@end
@implementation FBFlutterRouterApiCodecReader
- (nullable id)readValueOfType:(UInt8)type 
{
  switch (type) {
    case 128:     
      return [FBCommonParams fromMap:[self readValue]];
    
    default:    
      return [super readValueOfType:type];
    
  }
}
@end

//FB Flutter Router 编码器
@interface FBFlutterRouterApiCodecWriter : FlutterStandardWriter
@end
@implementation FBFlutterRouterApiCodecWriter
- (void)writeValue:(id)value 
{
  if ([value isKindOfClass:[FBCommonParams class]]) {
    [self writeByte:128];
    [self writeValue:[value toMap]];
  } else 
{
    [super writeValue:value];
  }
}
@end

//FB Flutter Router编码解码器
@interface FBFlutterRouterApiCodecReaderWriter : FlutterStandardReaderWriter
@end
@implementation FBFlutterRouterApiCodecReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
  return [[FBFlutterRouterApiCodecWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
  return [[FBFlutterRouterApiCodecReader alloc] initWithData:data];
}
@end

// FB Flutter Router编解码器初始化
NSObject<FlutterMessageCodec> *FBFlutterRouterApiGetCodec() {
  static dispatch_once_t sPred = 0;
  static FlutterStandardMessageCodec *sSharedObject = nil;
  dispatch_once(&sPred, ^{
    FBFlutterRouterApiCodecReaderWriter *readerWriter = [[FBFlutterRouterApiCodecReaderWriter alloc] init];
    sSharedObject = [FlutterStandardMessageCodec codecWithReaderWriter:readerWriter];
  });
  return sSharedObject;
}


/**
 * native 侧给 flutter 侧发生channel事件
 */
@interface FBFlutterRouterApi ()
@property (nonatomic, strong) NSObject<FlutterBinaryMessenger> *binaryMessenger;
@end

@implementation FBFlutterRouterApi

- (instancetype)initWithBinaryMessenger:(NSObject<FlutterBinaryMessenger> *)binaryMessenger {
  self = [super init];
  if (self) {
    _binaryMessenger = binaryMessenger;
  }
  return self;
}
- (void)pushRouteParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.pushRoute"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)popRouteParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.popRoute"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)removeRouteParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.removeRoute"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)onForegroundParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.onForeground"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)onBackgroundParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.onBackground"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)onNativeResultParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.onNativeResult"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)onContainerShowParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.onContainerShow"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)onContainerHideParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.onContainerHide"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)sendEventToFlutterParam:(FBCommonParams *)arg_param completion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.sendEventToFlutter"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:@[arg_param ?: [NSNull null]] reply:^(id reply) {
    completion(nil);
  }];
}
- (void)onBackPressedWithCompletion:(void(^)(NSError *_Nullable))completion {
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:@"dev.flutter.pigeon.FlutterRouterApi.onBackPressed"
      binaryMessenger:self.binaryMessenger
      codec:FBFlutterRouterApiGetCodec()];
  [channel sendMessage:nil reply:^(id reply) {
    completion(nil);
  }];
}
@end
