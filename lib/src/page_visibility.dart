// Copyright (c) 2019 Alibaba Group. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'logger.dart';

///Observer for all pages visibility
/// 全局页面可见性观察
class GlobalPageVisibilityObserver {
  void onPagePush(Route<dynamic> route) {}

  void onPageShow(Route<dynamic> route) {}

  void onPageHide(Route<dynamic> route) {}

  void onPagePop(Route<dynamic> route) {}

  void onForeground(Route<dynamic> route) {}

  void onBackground(Route<dynamic> route) {}
}

///Observer for single page visibility
/// 单页面可见性观察
class PageVisibilityObserver {
  ///
  /// Tip:If you want to do things when page is created,
  /// please in your [StatefulWidget]'s [State]
  /// and write your code in [initState] method to initialize
  /// 页面创建的时候做一些事情，写在 initState 里
  ///
  /// And If you want to do things when page is destory,
  /// please write code in the [dispose] method
  /// 
  /// 页面销毁时做一些事情，写在dispose里
  ///

  /// It can be regarded as Android "onResume" or iOS "viewDidAppear"
  void onPageShow() {}

  /// It can be regarded as Android "onStop" or iOS "viewDidDisappear"
  void onPageHide() {}

  void onForeground() {}

  void onBackground() {}
}

class PageVisibilityBinding {
  PageVisibilityBinding._();

  static final PageVisibilityBinding instance = PageVisibilityBinding._();

  ///listeners for single page event
  ///监听单页面事件
  final Map<Route<dynamic>, Set<PageVisibilityObserver>> _listeners =
      <Route<dynamic>, Set<PageVisibilityObserver>>{};

  ///listeners for all pages event
  ///全局事件监听
  final Set<GlobalPageVisibilityObserver> _globalListeners =
      <GlobalPageVisibilityObserver>{};

  /// Registers the given object and route as a binding observer.
  /// 将给定的对象和路由注册为绑定观察者
  void addObserver(PageVisibilityObserver observer, Route<dynamic> route) {
    //注册route，如果_listeners里不存在这个注册的route
    // <PageVisibilityObserver>{} 是一个set集合，不是一个对象
    // 返回这个route 对应的set集合
    final observers =
        _listeners.putIfAbsent(route, () => <PageVisibilityObserver>{});
    // 将observer添加进去
    observers.add(observer);
    Logger.log(
        'page_visibility, #addObserver, $observers, ${route.settings.name}');
  }

  /// Unregisters the given observer.
  /// 移除监听
  void removeObserver(PageVisibilityObserver observer) {
    for (final route in _listeners.keys) {
      final observers = _listeners[route];
      // 从set集合里移除这个observer
      observers?.remove(observer);
    }
    Logger.log('page_visibility, #removeObserver, $observer');
  }

  ///Register [observer] to [_globalListeners] set
  ///注册全局监听器
  void addGlobalObserver(GlobalPageVisibilityObserver observer) {
    _globalListeners.add(observer);
    Logger.log('page_visibility, #addGlobalObserver, $observer');
  }

  ///Register [observer] from [_globalListeners] set
  /// 移除全局监听器
  void removeGlobalObserver(GlobalPageVisibilityObserver observer) {
    _globalListeners.remove(observer);
    Logger.log('page_visibility, #removeGlobalObserver, $observer');
  }

  // 分发页面全局push事件
  void dispatchPagePushEvent(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    ///just dispatch for global observers
    dispatchGlobalPagePushEvent(route);
  }
  
  // 分发单页面show事件
  void dispatchPageShowEvent(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    final observers = _listeners[route]?.toList();
    if (observers != null) {
      for (var observer in observers) {
        try {
          observer.onPageShow();
        } on Exception catch (e) {
          Logger.log(e.toString());
        }
      }
    }
    Logger.log(
        'page_visibility, #dispatchPageShowEvent, ${route.settings.name}');
    // 然后分发一次全局页面show事件
    dispatchGlobalPageShowEvent(route);
  }

  ///When page show first time,we should dispatch event in [FrameCallback]
  ///to avoid the page can't receive the show event
  /// 当页面第一次显示时，我们应该在 [FrameCallback] 中分发事件
  /// 以避免页面无法接收到显示事件。
  void dispatchPageShowEventOnPageShowFirstTime(Route<dynamic>? route) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      dispatchPageShowEvent(route);
    });
  }
  
  // 分发页面PageHide事件
  void dispatchPageHideEvent(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    final observers = _listeners[route]?.toList();
    if (observers != null) {
      for (var observer in observers) {
        try {
          observer.onPageHide();
        } on Exception catch (e) {
          Logger.log(e.toString());
        }
      }
    }
    Logger.log(
        'page_visibility, #dispatchPageHideEvent, ${route.settings.name}');

    dispatchGlobalPageHideEvent(route);
  }
 
  // 分发页面pop事件（只分发到全局监听对象上）
  void dispatchPagePopEvent(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    ///just dispatch for global observers
    /// 仅对全局观察者进行分发
    dispatchGlobalPagePopEvent(route);
  }
  
  // 分发回到前台监听事件
  void dispatchPageForgroundEvent(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    final observers = _listeners[route]?.toList();
    if (observers != null) {
      for (var observer in observers) {
        try {
          observer.onForeground();
        } on Exception catch (e) {
          Logger.log(e.toString());
        }
      }
    }

    Logger.log(
        'page_visibility, #dispatchPageForgroundEvent, ${route.settings.name}');

    dispatchGlobalForgroundEvent(route);
  }
  
  
  // 分发进入后台监听事件
  void dispatchPageBackgroundEvent(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    final observers = _listeners[route]?.toList();
    if (observers != null) {
      for (var observer in observers) {
        try {
          observer.onBackground();
        } on Exception catch (e) {
          Logger.log(e.toString());
        }
      }
    }

    Logger.log('page_visibility, '
        '#dispatchPageBackgroundEvent, ${route.settings.name}');

    dispatchGlobalBackgroundEvent(route);
  }
  
  // 对全局观察者调用，onPagePush事件
  void dispatchGlobalPagePushEvent(Route<dynamic> route) {
    final globalObserversList = _globalListeners.toList();

    for (var observer in globalObserversList) {
      observer.onPagePush(route);
    }

    Logger.log('page_visibility, #dispatchGlobalPagePushEvent, '
        '${route.settings.name}');
  }
  
  // 对全局观察者调用onPageShow事件
  void dispatchGlobalPageShowEvent(Route<dynamic> route) {
    final globalObserversList = _globalListeners.toList();

    for (var observer in globalObserversList) {
      observer.onPageShow(route);
    }

    Logger.log('page_visibility, #dispatchGlobalPageShowEvent, '
        '${route.settings.name}');
  }
  
  //对全局观察者调用页面onPageHide事件
  void dispatchGlobalPageHideEvent(Route<dynamic> route) {
    final globalObserversList = _globalListeners.toList();

    for (var observer in globalObserversList) {
      observer.onPageHide(route);
    }

    Logger.log('page_visibility, #dispatchGlobalPageHideEvent, '
        '${route.settings.name}');
  }

  //对全局观察者分发onPagePop生命周期
  void dispatchGlobalPagePopEvent(Route<dynamic> route) {
    final globalObserversList = _globalListeners.toList();
    for (var observer in globalObserversList) {
      observer.onPagePop(route);
    }

    Logger.log('page_visibility, #dispatchGlobalPagePopEvent, '
        '${route.settings.name}');
  }
  
  // 全局观察者，切回前台事件
  void dispatchGlobalForgroundEvent(Route<dynamic> route) {
    final globalObserversList = _globalListeners.toList();
    for (var observer in globalObserversList) {
      observer.onForeground(route);
    }

    Logger.log('page_visibility, #dispatchGlobalForgroudEvent');
  }
  
  // 全局观察者，回到后台事件
  void dispatchGlobalBackgroundEvent(Route<dynamic> route) {
    final globalObserversList = _globalListeners.toList();
    for (var observer in globalObserversList) {
      observer.onBackground(route);
    }

    Logger.log('page_visibility, #dispatchGlobalBackgroundEvent');
  }
}
