// Copyright (c) 2019 Alibaba Group. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'boost_navigator.dart';

/// The request object in Interceptor,which is to passed
/// 拦截器里的请求对象，用来传递
class BoostInterceptorOption {
  BoostInterceptorOption(this.name,
      {this.uniqueId, this.isFromHost, this.arguments});

  /// Your page name in route table
  /// 在router table 中的页面名称
  String? name;

  /// Unique identifier for the route
  String? uniqueId;

  /// Whether or not the flutter page was opened by host
  /// host 是否打开了flutter页面
  bool? isFromHost;

  /// The arguments you want to pass in next page
  /// 下一个页面的参数
  Map<String, dynamic>? arguments;

  @override
  String toString() => "Instance of 'BoostInterceptorOption'(name:$name, "
      "isFromHost:$isFromHost, uniqueId:$uniqueId, arguments:$arguments)";
}

enum InterceptorResultType {
  next,
  resolve,
}

class InterceptorState<T> {
  InterceptorState(this.data, [this.type = InterceptorResultType.next]);

  T data;
  InterceptorResultType type;
}

class _BaseHandler {
  InterceptorState? get state => _state;
  InterceptorState? _state;
}

/// Handler for push interceptor.
/// push 拦截器
class PushInterceptorHandler extends _BaseHandler {
  /// Continue to call the next push interceptor.
  /// 继续调用下一个push拦截器
  void next(BoostInterceptorOption options) {
    _state = InterceptorState<BoostInterceptorOption>(options);
  }

  /// Return the result directly!
  /// 直接返回结果！
  /// Other interceptor(s) will not be executed.
  /// 其他拦截器将不会被执行。
  ///
  /// [result]: Response object to return.
  /// [result]：要返回的响应对象。
  void resolve(Object result) {
    _state = InterceptorState<Object>(result, InterceptorResultType.resolve);
  }
}

///The Interceptor to intercept the [push] method in [BoostNavigator]
///拦截器用于拦截 [BoostNavigator] 中的 [push] 方法
class BoostInterceptor {
  /// The callback will be executed before the push is initiated.
  /// 回调将在push操作开始之前执行
  ///
  /// If you want to continue the push, call [handler.next].
  /// 如果你想继续进行推送，调用 [handler.next]。
  ///
  /// If you want to complete the push with some custom data，
  /// you can resolve a [result] object with [handler.resolve].
  /// 如果你想用一些自定义数据完成推送，可以使用 [handler.resolve] 解析一个 [result] 对象。
  void onPrePush(
          BoostInterceptorOption option, PushInterceptorHandler handler) =>
      handler.next(option);

  /// The callback will be executed after the push have been finish.
  /// 回调将在push完成后执行
  ///
  /// If have other interceptors, call [handler.next].
  /// 如果有其他拦截器，调用 [handler.next]。
  ///
  /// If you want to complete the push finish event with some custom data，
  /// you can resolve a [result] object with [handler.resolve].
  /// 如果你想在push完成事件时带上自定义数据，可以使用 [handler.resolve] 解析一个 [result] 对象。
  void onPostPush(
          BoostInterceptorOption option, PushInterceptorHandler handler) =>
      handler.next(option);
}
