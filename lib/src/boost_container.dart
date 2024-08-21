// Copyright (c) 2019 Alibaba Group. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'boost_channel.dart';
import 'boost_navigator.dart';
import 'flutter_boost_app.dart';

/// This class is an abstraction of native containers
/// Each of which has a bunch of pages in the [NavigatorExt]
/// 这个类是对本地容器的抽象，每个容器中都包含一组页面，这些页面在 [NavigatorExt] 中进行管理
class BoostContainer extends ChangeNotifier {
  BoostContainer({this.key, required this.pageInfo}) {
    _pages.add(BoostPage.create(pageInfo));
  }

  static BoostContainer? of(BuildContext context) {
    final state = context.findAncestorStateOfType<BoostContainerState>();
    return state?.container;
  }

  /// The local key
  /// 本地key
  final LocalKey? key;

  /// The pageInfo for this container
  /// 当前container的pageInfo
  final PageInfo pageInfo;

  /// A list of page in this container
  /// container 容器中的页面列表
  final List<BoostPage<dynamic>> _pages = <BoostPage<dynamic>>[];

  /// Getter for a list that cannot be changed
  /// 返回页面列表页，并且页面列表页是不可修改的
  List<BoostPage<dynamic>> get pages => List.unmodifiable(_pages);

  /// To get the top page in this container
  /// 返回容器中最顶部的页面
  BoostPage<dynamic> get topPage => pages.last;

  /// Number of pages
  /// 当前容器包含的页面个数
  int numPages() => pages.length;

  /// The navigator used in this container
  NavigatorState? get navigator => _navKey.currentState;

  /// The [GlobalKey] to get the [NavigatorExt] in this container
  /// 通过_navKey可以获取NavigatorExt组件state
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  /// intercept page's backPressed event
  ///拦截页面的backPressed事件,自定义返回操作
  VoidCallback? backPressedHandler;

  /// add a [BoostPage] in this container and return its future result
  /// 在container容器中添加一个BoostPage，并返回一个container
  Future<T>? addPage<T extends Object?>(BoostPage page) {
    // 只有一个页面的时候
    if (numPages() == 1) {
      /// disable the native slide pop gesture
      /// only iOS will receive this event ,Android will do nothing
      ///禁用本机滑动弹出手势
      ///只有iOS会接收这个事件，Android什么都不做
      BoostChannel.instance.disablePopGesture(containerId: pageInfo.uniqueId!);
    }
    _pages.add(page);
    notifyListeners();
    return page.popped.then((value) => value as T);
  }

  /// remove a specific [BoostPage]
  /// 移除一个具体的页面
  void removePage(BoostPage? page, {dynamic result}) {
    if (page != null) {
      if (removePageInternal(page, result: result)) {
        notifyListeners();
      }
    }
  }
  
  // 移除 container 内部的BoostPage
  bool removePageInternal(BoostPage page, {dynamic result}) {
    // 如果页面数量为2
    if (numPages() == 2) {
      /// enable the native slide pop gesture
      /// only iOS will receive this event, Android will do nothing
      /// 启用本地滑动弹出手势
      /// 仅 iOS 会接收到此事件，Android 不会做任何操作
      BoostChannel.instance.enablePopGesture(containerId: pageInfo.uniqueId!);
    }
    // 如果从_pages中移除了page
    bool retVal = _pages.remove(page);
    if (retVal) {
      // 调用 page 的 _popCompleter
      page.didComplete(result);
    }
    return retVal;
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'BoostContainer')}(name:${pageInfo.pageName},'
      ' pages:$pages)';
}

/// The Widget build for a [BoostContainer]
///
/// It overrides the "==" and "hashCode",
/// to avoid rebuilding when its parent element call element.updateChild
class BoostContainerWidget extends StatefulWidget {
  BoostContainerWidget({LocalKey? key, required this.container})
      : super(key: container.key);

  /// The container this widget belong
  /// 这个 widget 所属的 container
  final BoostContainer container;

  @override
  State<BoostContainerWidget> createState() => BoostContainerState();

  @override
  // ignore: invalid_override_of_non_virtual_member
  bool operator ==(Object other) {
    if (other is BoostContainerWidget) {
      var otherWidget = other;
      return container.pageInfo.uniqueId ==
          otherWidget.container.pageInfo.uniqueId;
    }
    return super == other;
  }

  @override
  // ignore: invalid_override_of_non_virtual_member
  int get hashCode => container.pageInfo.uniqueId.hashCode;
}

class BoostContainerState extends State<BoostContainerWidget> {
  /// 获取container
  BoostContainer get container => widget.container;
  
  // 更新页面list
  void _updatePagesList(BoostPage page, dynamic result) {
    assert(container.topPage == page);
    container.removePageInternal(page, result: result);
  }

  @override
  void initState() {
    super.initState();
    container.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(covariant BoostContainerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget != widget) {
      oldWidget.container.removeListener(_onRouteChanged);
      container.addListener(_onRouteChanged);
    }
  }

  ///just refresh
  ///只刷新
  void _onRouteChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
        controller: HeroController(),
        child: NavigatorExt(
          key: container._navKey,
          pages: List<Page<dynamic>>.of(container.pages),
          onPopPage: (route, result) {
            if (route.didPop(result)) {
              assert(route.settings is BoostPage);
              // 执行页面的移除操作
              _updatePagesList(route.settings as BoostPage, result);
              return true;
            }
            return false;
          },
          observers: <NavigatorObserver>[
            BoostNavigatorObserver(),
          ],
        ));
  }

  @override
  void dispose() {
    container.removeListener(_onRouteChanged);
    super.dispose();
  }
}

/// This class is make user call
/// "Navigator.pop()" is equal to BoostNavigator.instance.pop()
/// 这个类是让用户调用
/// Navigator.pop() 等同于 BoostNavigator.instance.pop()
class NavigatorExt extends Navigator {
  const NavigatorExt({
    Key? key,
    required List<Page<dynamic>> pages,
    PopPageCallback? onPopPage,
    required List<NavigatorObserver> observers,
  }) : super(
            key: key, pages: pages, onPopPage: onPopPage, observers: observers);

  @override
  NavigatorState createState() => NavigatorExtState();
}

class NavigatorExtState extends NavigatorState {

  // 通过 routeName push 跳新页面
  @override
  Future<T?> pushNamed<T extends Object?>(String routeName,
      {Object? arguments}) {
    if (arguments == null) {
      return BoostNavigator.instance
          .push(routeName)
          .then((value) => value as T);
    }

    if (arguments is Map<String, dynamic>) {
      return BoostNavigator.instance
          .push(routeName, arguments: arguments)
          .then((value) => value as T);
    }

    if (arguments is Map) {
      return BoostNavigator.instance
          .push(routeName, arguments: Map<String, dynamic>.from(arguments))
          .then((value) => value as T);
    } else {
      assert(false, "arguments should be Map<String,dynamic> or Map");
      return BoostNavigator.instance
          .push(routeName)
          .then((value) => value as T);
    }
  }
  
  // 
  @override
  void pop<T extends Object?>([T? result]) {
    // Taking over container page
    // 接管容器页面
    if (!canPop()) {
      BoostNavigator.instance.pop(result ?? {});
    } else {
      super.pop(result);
    }
  }
}
