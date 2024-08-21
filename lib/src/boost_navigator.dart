// Copyright (c) 2019 Alibaba Group. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'boost_container.dart';
import 'container_overlay.dart';
import 'flutter_boost_app.dart';

typedef FlutterBoostRouteFactory = Route<dynamic>? Function(
    RouteSettings settings, String? uniqueId);

// 如果没有拿到注册的Route，就默认给一个空白的 Page Builder
FlutterBoostRouteFactory routeFactoryWrapper(
    FlutterBoostRouteFactory routeFactory) {
  return (settings, uniqueId) {
    var route = routeFactory(settings, uniqueId);
    if (route == null && settings.name == '/') {
      route = PageRouteBuilder<dynamic>(
          settings: settings, pageBuilder: (_, __, ___) => Container());
    }
    return route;
  };
}

/// A object that manages a set of pages with a hybrid stack.
/// 一个管理具有混合堆栈的页面集合的对象
///
class BoostNavigator {
  BoostNavigator._();

  /// The singleton for [BoostNavigator]
  /// 单例BoostNavigator
  static final BoostNavigator _instance = BoostNavigator._();

  /// The boost data center
  /// boost 数据中心
  FlutterBoostAppState? appState;

  /// The route table in flutter_boost
  late FlutterBoostRouteFactory _routeFactory;
  
  /// 在boostAPP初始化的时候，就会设置routeFactory
  set routeFactory(FlutterBoostRouteFactory routeFactory) =>
      _routeFactory = routeFactoryWrapper(routeFactory);

  FlutterBoostRouteFactory get routeFactory => _routeFactory;

  /// Use BoostNavigator.instance instead
  @Deprecated('Use `instance` instead.')
  static BoostNavigator of() => instance;

  static BoostNavigator get instance {
    // If the root ioslate has initialized, |appState| should not be null.
    _instance.appState ??= overlayKey.currentContext
        ?.findAncestorStateOfType<FlutterBoostAppState>();
    return _instance;
  }

  /// Whether this page with the given [name] is a flutter page
  /// 给定name的页面是否是flutter页面
  ///
  /// If the name of route can be found in route table then return true,
  /// otherwise return false.
  bool isFlutterPage(String name) =>
      routeFactory(RouteSettings(name: name), null) != null;

  /// 将具有给定 [name] 的页面推送到混合栈中。
  ///  [arguments] 是你想传递到下一个页面的参数
  ///  如果 [withContainer] 为 true，下一个路由将带有一个原生容器
  /// Android Activity / iOS UIViewController）。
  /// 如果 [opaque] 为 true，页面是不透明的（即不透明）。
  ///
  /// 此方法将返回一个 Future<T>，其结果是页面弹出的结果
  Future<T> push<T extends Object?>(String name,
      {Map<String, dynamic>? arguments,
      bool withContainer = false,
      bool opaque = true}) {
    assert(
        appState != null, 'Please check if the engine has been initialized!');
    bool isFlutter = isFlutterPage(name);
    // flutter页面，切设置了容器内显示
    if (isFlutter && withContainer) {
      // 1. open flutter page with container
      // 打开一个flutter page，在这个当前的容器上
      // Intercepted in BoostFlutterRouterApi.pushRoute
      return appState!.pushWithResult(name,
          arguments: arguments, withContainer: withContainer, opaque: opaque);
    } else {
      // 2. open native page or flutter page without container
      // 在这个container之外，打开一个native页面或者flutter页面
      return appState!.pushWithInterceptor(
          name, 
          false /* isFromHost */, 
          isFlutter,
          arguments: arguments, withContainer: withContainer, opaque: opaque);
    }
  }

  /// 这个 API 做两件事：
  /// 1. 将新页面推送到 pageStack 中。
  /// 2. 移除（弹出）之前的页面。
  Future<T> pushReplacement<T extends Object?>(String name,
      {Map<String, dynamic>? arguments, bool withContainer = false}) async {
    final String? id = getTopPageInfo()?.uniqueId;
    final result =
        push<T>(name, arguments: arguments, withContainer: withContainer);

    if (id != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        remove(id);
      });
    }
    return result;
  }

  /// Pop the top-most page off the hybrid stack.
  /// 从混合栈中弹出最顶部的页面
  Future<bool> pop<T extends Object?>([T? result]) async {
    assert(
        appState != null, 'Please check if the engine has been initialized!');
    return await appState!.popWithResult(result);
  }

  /// 从混合栈中弹出页面，直到遇到指定的页面
  Future<void> popUntil({String? route, String? uniqueId}) async {
    assert(
        appState != null, 'Please check if the engine has been initialized!');
    return appState!.popUntil(route: route, uniqueId: uniqueId);
  }

  /// 从混合栈中移除具有给定 [uniqueId] 的页面
  ///
  /// 这个 API 用于向后兼容。
  /// 请改用 [BoostNavigator.pop]。
  Future<bool> remove(String? uniqueId,
      {Map<String, dynamic>? arguments}) async {
    assert(
        appState != null, 'Please check if the engine has been initialized!');
    return await appState!.removeWithResult(uniqueId, arguments);
  }

  /// Retrieves the infomation of the top-most flutter page
  /// on the hybrid stack, such as uniqueId, pagename, etc;
  ///
  /// This is a legacy API for backwards compatibility.
  PageInfo? getTopPageInfo() => appState!.getTopPageInfo();

  @Deprecated('use getPageInfoByContext(BuildContext context) instead')
  PageInfo? getTopByContext(BuildContext context) =>
      BoostContainer.of(context)?.pageInfo;

  PageInfo? getPageInfoByContext(BuildContext context) =>
      BoostContainer.of(context)?.pageInfo;

  bool isTopPage(BuildContext context) {
    return getPageInfoByContext(context) == getTopPageInfo();
  }

  /// Return the number of flutter pages
  ///
  /// This is a legacy API for backwards compatibility.
  int pageSize() => appState!.pageSize();
}

/// The PageInfo use in FlutterBoost ,it is not a public api
/// PageInfo 只在 FlutterBoost 内部使用，不是一个公共的api
class PageInfo {
  PageInfo({this.pageName, this.uniqueId, this.arguments, this.withContainer});

  bool? withContainer;
  String? pageName;
  String? uniqueId;
  Map<String, dynamic>? arguments;
}
