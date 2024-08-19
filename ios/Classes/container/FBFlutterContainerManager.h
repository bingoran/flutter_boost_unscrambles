/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2019 Alibaba Group
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "FBFlutterContainer.h"

@interface FBFlutterContainerManager : NSObject
// 通过这个uniqueId作为唯一标识，存放FBFlutterContainer
- (void)addContainer:(id<FBFlutterContainer>)container forUniqueId:(NSString *)uniqueId;
// 通过这个uniqueId作为唯一标识，存放FBFlutterContainer；移除旧的，添加新的
- (void)activeContainer:(id<FBFlutterContainer>)container forUniqueId:(NSString *)uniqueId;
// 通过唯一标识，移除容器
- (void)removeContainerByUniqueId:(NSString *)uniqueId;
// 通过唯一标识返回FBFlutterContainer
- (id<FBFlutterContainer>)findContainerByUniqueId:(NSString *)uniqueId;
// 返回最顶层的FBFlutterContainer
- (id<FBFlutterContainer>)getTopContainer;
// 判断是否是最顶层的FBFlutterContainer
- (BOOL)isTopContainer:(NSString *)uniqueId;
// 返回所有container数量
- (NSInteger)containerSize;
@end
