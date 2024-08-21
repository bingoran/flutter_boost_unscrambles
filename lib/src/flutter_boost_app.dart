// Copyright (c) 2019 Alibaba Group. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'boost_channel.dart';
import 'boost_container.dart';
import 'boost_flutter_binding.dart';
import 'boost_flutter_router_api.dart';
import 'boost_interceptor.dart';
import 'boost_lifecycle_binding.dart';
import 'boost_navigator.dart';
import 'boost_operation_queue.dart';
import 'container_overlay.dart';
import 'logger.dart';
import 'messages.dart';

typedef FlutterBoostAppBuilder = Widget Function(Widget home);

class FlutterBoostApp extends StatefulWidget {
  FlutterBoostApp(
    FlutterBoostRouteFactory routeFactory, {
    Key? key,
    FlutterBoostAppBuilder? appBuilder,
    String? initialRoute,

    ///interceptors is to intercept push operation now
    /// 拦截器：拦截push操作
    List<BoostInterceptor>? interceptors,
  })  : appBuilder = appBuilder ?? _defaultAppBuilder,
        interceptors = interceptors ?? <BoostInterceptor>[], // boost 拦截器
        initialRoute = initialRoute ?? '/', // 初始化路由
        super(key: key) {
    // 根据页面router工厂，返回对应的页面
    BoostNavigator.instance.routeFactory = routeFactory;
  }

  final FlutterBoostAppBuilder appBuilder;
  final String initialRoute;

  ///A list of [BoostInterceptor],to intercept operations when push
  final List<BoostInterceptor> interceptors;

  /// default builder for app
  /// 默认app builder
  static Widget _defaultAppBuilder(Widget home) {
    /// use builder param instead of home,to avoid Navigator.pop
    /// 使用构造器参数（builder param）代替 home，以避免 Navigator.pop
    return MaterialApp(home: home, builder: (_, __) => home);
  }

  @override
  State<StatefulWidget> createState() => FlutterBoostAppState();
}

class FlutterBoostAppState extends State<FlutterBoostApp> {
  // APP 生命周期改变key
  static const String _appLifecycleChangedKey = "app_lifecycle_changed_key";
  // 等待结果
  final Map<String, Completer<Object?>> _pendingResult =
      <String, Completer<Object?>>{};
  // 存放 flutterboost BoostContainer
  final List<BoostContainer> _containers = <BoostContainer>[];
  // 获取容器列表
  List<BoostContainer> get containers => _containers;

  /// All interceptors from widget
  /// 所有widget的拦截器
  List<BoostInterceptor> get interceptors => widget.interceptors;
  // 得到最顶部的BoostContainer
  BoostContainer? get topContainer =>
      _containers.isNotEmpty ? _containers.last : null;
  
  // 存放 NativeRouterApi 实例
  NativeRouterApi get nativeRouterApi => _nativeRouterApi;
  late NativeRouterApi _nativeRouterApi;

  // 实际上是在Dart端对应的MessageChannel
  BoostFlutterRouterApi get boostFlutterRouterApi => _boostFlutterRouterApi;
  late BoostFlutterRouterApi _boostFlutterRouterApi;

  final Set<int> _activePointers = <int>{};

  ///Things about method channel
  /// 监听表
  final Map<String, List<EventListener>> _listenersTable =
      <String, List<EventListener>>{};
  
  // 保存移除EventListener的回调
  late VoidCallback _lifecycleStateListenerRemover;

  /// A list of native page's 'Key' who are opened by dart side
  /// 一个由 Dart 端打开的native页面的 'Key' 列表
  final List<String> _nativePageKeys = <String>[];

  /// To get the last one in the _nativePageKeys list
  /// 获取_nativePageKeys列表中的最后一个
  String get _topNativePage => _nativePageKeys.last;

  @override
  void initState() {
    // 初始化前，必须先调用下 BoostFlutterBinding
    assert(
        BoostFlutterBinding.instance != null,
        'BoostFlutterBinding is not initialized，'
        'please refer to "class CustomFlutterBinding" in example project');
    // 初始化和native通讯的类
    _nativeRouterApi = NativeRouterApi();
    // 初始化接收native 消息的channel
    _boostFlutterRouterApi = BoostFlutterRouterApi(this);

    /// create the container matching the initial route
    /// 场景一个BoostContainer，匹配初始化路由
    final BoostContainer initialContainer =
        _createContainer(PageInfo(pageName: widget.initialRoute));
    // 添加进容器数组
    _containers.add(initialContainer);
    super.initState();

    // Make sure that the widget in the tree that matches [overlayKey]
    // is already mounted, or [refreshOnPush] will fail.
    // 确保树中的小部件与 [overlayKey] 匹配
    // 已经挂载，否则 [refreshOnPush] 将会失败。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // try to restore routes from host when hot restart.
      assert(() {
        _restoreStackForHotRestart();
        return true;
      }());

      refreshOnPush(initialContainer);
      //标记flutter端已经可以接收channel通讯
      _boostFlutterRouterApi.isEnvReady = true;
      // 添加APP生命周期状态监听
      _addAppLifecycleStateEventListener();
      // 执行对列中的操作
      BoostOperationQueue.instance.runPendingOperations();
    });
  }

  ///Setup the AppLifecycleState change event launched from native
  ///设置从本地启动的 AppLifecycleState 更改事件
  ///Here,the [AppLifecycleState] is depends on the native container's num
  ///在这里，[AppLifecycleState] 取决于本地容器的数量。
  ///if container num >= 1,the state == [AppLifecycleState.resumed]
  ///如果容器数量 >= 1，则状态为 [AppLifecycleState.resumed]；
  ///else state == [AppLifecycleState.paused]
  ///否则，状态为 [AppLifecycleState.paused]。
  void _addAppLifecycleStateEventListener() {
    _lifecycleStateListenerRemover = BoostChannel.instance
        .addEventListener(_appLifecycleChangedKey, (key, arguments) {
      //we just deal two situation,resume and pause
      //and 0 is resumed
      //and 2 is paused

      final int? index = arguments["lifecycleState"];

      if (index == AppLifecycleState.resumed.index) {
        BoostFlutterBinding.instance!
            .changeAppLifecycleState(AppLifecycleState.resumed);
      } else if (index == AppLifecycleState.paused.index) {
        BoostFlutterBinding.instance!
            .changeAppLifecycleState(AppLifecycleState.paused);
      }
      return Future<dynamic>.value();
    });
  }

  @override
  void dispose() {
    _lifecycleStateListenerRemover.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.appBuilder(WillPopScope(
        onWillPop: () async {
          final canPop = topContainer!.navigator!.canPop();
          if (canPop) {
            topContainer!.navigator!.pop();
            return true;
          }
          return false;
        },
        child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerUp: _handlePointerUpOrCancel,
            onPointerCancel: _handlePointerUpOrCancel,
            child: Overlay(
              key: overlayKey,
              initialEntries: const <OverlayEntry>[],
            ))));
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
  }

  void _cancelActivePointers() {
    _activePointers.toList().forEach(WidgetsBinding.instance.cancelPointer);
  }
 
  // 生成一个UniqueId
  String _createUniqueId(String? pageName) {
    return '${DateTime.now().millisecondsSinceEpoch}_$pageName';
  }
  
  // 创建BoostContainer的工具函数
  BoostContainer _createContainer(PageInfo pageInfo) {
    pageInfo.uniqueId ??= _createUniqueId(pageInfo.pageName);
    return BoostContainer(
        key: ValueKey<String?>(pageInfo.uniqueId), pageInfo: pageInfo);
  }
  
  // 保存堆栈，用于热启动
  Future<void> _saveStackForHotRestart() async {
    final stack = StackInfo();
    stack.ids = <String?>[];
    stack.containers = <String?, FlutterContainer?>{};
    for (var container in _containers) {
      var uniqueId = container.pageInfo.uniqueId;
      stack.ids!.add(uniqueId);
      var flutterContainer = FlutterContainer();
      flutterContainer.pages = <FlutterPage?>[];
      for (var page in container.pages) {
        flutterContainer.pages!.add(FlutterPage(
            withContainer: page.pageInfo.withContainer,
            pageName: page.pageInfo.pageName,
            uniqueId: page.pageInfo.uniqueId,
            arguments: page.pageInfo.arguments));
      }
      stack.containers![uniqueId] = flutterContainer;
    }

    await nativeRouterApi.saveStackToHost(stack);
    Logger.log('_saveStackForHotRestart, ${stack.ids}, ${stack.containers}');
  }
  
  // 热更新恢复页面堆栈
  Future<void> _restoreStackForHotRestart() async {
    // 获取到native侧保存的堆栈
    final stack = await nativeRouterApi.getStackFromHost();
    final List<String?>? ids = stack.ids;
    final Map<String?, FlutterContainer?>? containers = stack.containers;
    if (ids != null && containers != null) {
      for (var id in ids) {
        var withContainer = true;
        // container不为空
        final FlutterContainer? container = containers[id];
        // container 和内部 page 都不为空
        if (container != null && container.pages != null) {
          for (var page in container.pages as List<FlutterPage?>) {
            // 拿到page
            if (page != null && page.arguments != null) {
              // 将有效的参数，重新组装到args中
              Map<String, Object> args = <String, Object>{};
              for (var key in page.arguments!.keys) {
                if (key != null && page.arguments![key] != null) {
                  args[key] = page.arguments![key]!;
                }
              }
              
              // 首先是push一个Boost Container处理，然后之后的page，都是附加到这个Container之上
              withContainer
                  ? pushContainer(page.pageName,
                      uniqueId: page.uniqueId, arguments: args)
                  : pushPage(page.pageName,
                      uniqueId: page.uniqueId, arguments: args);
              withContainer = false;
            }
          }
        }
      }
    }
    Logger.log('_restoreStackForHotRestart, $ids, $containers');
  }
  
  // push 拦截器
  Future<T> pushWithInterceptor<T extends Object?>(
      String? name, bool isFromHost, bool isFlutterPage,
      {Map<String, dynamic>? arguments,
      String? uniqueId,
      bool? withContainer,
      bool opaque = true}) {
    Logger.log('pushWithInterceptor, uniqueId=$uniqueId, name=$name');
    // push 参数
    var pushOption = BoostInterceptorOption(name,
        uniqueId: uniqueId,
        isFromHost: isFromHost,
        arguments: arguments ?? <String, dynamic>{});
    
    // 执行拦截器
    InterceptorState<BoostInterceptorOption>? state =
        InterceptorState<BoostInterceptorOption>(pushOption);
    for (var interceptor in interceptors) {
      final pushHandler = PushInterceptorHandler();
      // 即将push的一些操作
      interceptor.onPrePush(state!.data, pushHandler);

      // user resolve or do nothing
      if (pushHandler.state?.type != InterceptorResultType.next) {
        Logger.log('The page was intercepted by user. name:$name, '
            'isFromHost=$isFromHost, isFlutterPage=$isFlutterPage');
        return Future<T>.value(state.data as T);
      }
      state = pushHandler.state as InterceptorState<BoostInterceptorOption>?;
    }
    
    // 如果没有拦截，则进行正常的push操作
    if (state?.type == InterceptorResultType.next) {
      pushOption = state!.data;
      // isFromHost 如果是native发起打开，为true，如果是flutter发起打开，是false
      if (isFromHost) {
        // 新增一个contianer在最上面
        pushContainer(name,
            uniqueId: pushOption.uniqueId,
            isFromHost: isFromHost,
            arguments: pushOption.arguments);
        // 自己新增的
        return Future<T>.value();
      } else {
        // 如果是flutter页面（注册的页面中能找到页面）
        if (isFlutterPage) {
          return pushWithResult(pushOption.name,
              uniqueId: pushOption.uniqueId,
              arguments: pushOption.arguments,
              withContainer: withContainer!,
              opaque: opaque);
        } else {
          // 打开的是一个native页面
          final params = CommonParams()
            ..pageName = pushOption.name
            ..arguments = pushOption.arguments;
          nativeRouterApi.pushNativeRoute(params);
          // 等待页面返回结果
          return pendNativeResult(pushOption.name);
        }
      }
    }

    return Future<T>.value();
  }
  
  // native侧新增一个容器或者本地contiainer附加一个容器
  Future<T> pushWithResult<T extends Object?>(String? pageName,
      {String? uniqueId,
      Map<String, dynamic>? arguments,
      required bool withContainer,
      bool opaque = true}) {
    uniqueId ??= _createUniqueId(pageName);
    if (withContainer) {
      // flutter 端开一个新naitve FlutterVC容器加载页面
      final completer = Completer<T>();
      final params = CommonParams()
        ..pageName = pageName
        ..uniqueId = uniqueId
        ..opaque = opaque
        ..arguments = (arguments ?? <String, dynamic>{});
      nativeRouterApi.pushFlutterRoute(params);
      _pendingResult[uniqueId] = completer;
      return completer.future;
    } else {
      // 在当前的顶层container上附加一个新页面
      return pushPage(pageName, uniqueId: uniqueId, arguments: arguments);
    }
  }
  
  //在container上附加page
  Future<T> pushPage<T extends Object?>(String? pageName,
      {String? uniqueId, Map<String, dynamic>? arguments}) {
    Logger.log('pushPage, uniqueId=$uniqueId, name=$pageName,'
        ' arguments:$arguments, $topContainer');
    final pageInfo = PageInfo(
        pageName: pageName,
        uniqueId: uniqueId ?? _createUniqueId(pageName),
        arguments: arguments,
        withContainer: false);
    assert(topContainer != null);
    var result = topContainer!.addPage(BoostPage.create(pageInfo));
    _pushFinish(pageName, uniqueId: uniqueId, arguments: arguments);
    return result!.then((value) => value as T);
  }
  
  // push 到新的 container
  void pushContainer(String? pageName,
      {String? uniqueId,
      bool isFromHost = false,
      Map<String, dynamic>? arguments}) {
    // 取消页面上当前的点击事件
    _cancelActivePointers();
    // 看看_containers里有没有已经存在的page
    final existed = _findContainerByUniqueId(uniqueId);
    if (existed != null) {
      // 如果存在，而且如果不在最上层，就把找到的这个container移动到最上层
      if (topContainer?.pageInfo.uniqueId != uniqueId) {
        _containers.remove(existed);
        _containers.add(existed);

        //move the overlayEntry which matches this existing container to the top
        //页面层面操作移动到最顶层
        refreshOnMoveToTop(existed);
      }
    } else {
      // 如果不存在
      final pageInfo = PageInfo(
          pageName: pageName,
          uniqueId: uniqueId ?? _createUniqueId(pageName),
          arguments: arguments,
          withContainer: true);
      // 创建一个contaier
      final container = _createContainer(pageInfo);
      // 当前最顶部的container赋值为前一个container
      final previousContainer = topContainer;
      _containers.add(container);
      // 1、触发container的DidPush事件
      // 2、触发全局观察者onPagePush事件
      BoostLifecycleBinding.instance
          .containerDidPush(container, previousContainer);

      // Add a new overlay entry with this container
      // 在container上新增一个overlay entry
      refreshOnPush(container);
    }
    // 执行拦截器
    _pushFinish(pageName,
        uniqueId: uniqueId, isFromHost: isFromHost, arguments: arguments);
    Logger.log('pushContainer, uniqueId=$uniqueId, existed=$existed,'
        ' arguments:$arguments, $_containers');
  }
  
  // push 完成后，执行拦截器
  void _pushFinish(String? pageName,
      {String? uniqueId,
      bool isFromHost = false,
      Map<String, dynamic>? arguments}) {
    // 生成拦截参数
    var pushOption = BoostInterceptorOption(pageName,
        uniqueId: uniqueId,
        isFromHost: isFromHost,
        arguments: arguments ?? <String, dynamic>{});
    
    // 拦截器State
    InterceptorState<BoostInterceptorOption>? state =
        InterceptorState<BoostInterceptorOption>(pushOption);

    // 遍历拦截器
    for (var interceptor in interceptors) {
      final pushHandler = PushInterceptorHandler();
      // 拦截器处理完后，
      interceptor.onPostPush(state!.data, pushHandler);
      // user resolve or do nothing
      if (pushHandler.state?.type != InterceptorResultType.next) {
        break;
      }
      // 将上一个拦截器处理的数据继续向下一个拦截器传递
      state = pushHandler.state as InterceptorState<BoostInterceptorOption>?;
    }
  }
  
  // 从混合栈中弹出最顶部的页面，并返回弹出结果 true ｜ false
  Future<bool> popWithResult<T extends Object?>([T? result]) async {
    return await pop(result: result);
  }
  
  //从混合栈移除给定uniqueId的页面
  Future<bool> removeWithResult(
      [String? uniqueId, Map<String, dynamic>? result]) async {
    return await pop(uniqueId: uniqueId, result: result);
  }
  
  //pop 页面，直到
  void popUntil({String? route, String? uniqueId}) async {
    // 目标Container
    BoostContainer? targetContainer;
    // 目标page
    BoostPage? targetPage;
    // _containers 数量
    int popUntilIndex = _containers.length;
    // 如果uniqueId不为空
    if (uniqueId != null) {
      // 倒序遍历_containers
      for (int index = _containers.length - 1; index >= 0; index--) {
        // 遍历container中的page
        for (BoostPage page in _containers[index].pages) {
          // 找到了对应的container
          if (uniqueId == page.pageInfo.uniqueId ||
              uniqueId == _containers[index].pageInfo.uniqueId) {
            //uniqueId优先级更高，优先匹配
            targetContainer = _containers[index];
            targetPage = page;
            break;
          }
        }
        // 找到了目标container,记录下标
        if (targetContainer != null) {
          popUntilIndex = index;
          break;
        }
      }
    }
    
    // 目标container为空，但是 route（string）不为空
    if (targetContainer == null && route != null) {
      // 倒序遍历
      for (int index = _containers.length - 1; index >= 0; index--) {
        // 继续遍历container中的page
        for (BoostPage page in _containers[index].pages) {
          if (route == page.name) {
            // 找到了目标container
            targetContainer = _containers[index];
            targetPage = page;
            break;
          }
        }
        if (targetContainer != null) {
          popUntilIndex = index;
          break;
        }
      }
    }
    
    // 目标Container不为空 并且，并且目标Container不是最顶部的Container
    if (targetContainer != null && targetContainer != topContainer) {
      /// _containers item index would change when call 'nativeRouterApi.popRoute' method with sync.
      /// 当调用 nativeRouterApi.popRoute 方法进行同步操作时，_containers 的项索引会发生变化。
      /// clone _containers keep original item index.
      /// clone _containers 可以保持原始项的索引
      List<BoostContainer> containersTemp = [..._containers];
      // 倒序遍历，直到到达目标下标为止
      for (int index = containersTemp.length - 1;
          index > popUntilIndex;
          index--) {
        BoostContainer container = containersTemp[index];
        final params = CommonParams()
          ..pageName = container.pageInfo.pageName
          ..uniqueId = container.pageInfo.uniqueId
          ..arguments = {"animated": false};
        // native侧执行pop
        await nativeRouterApi.popRoute(params);
      }
      
      // 目标Container最顶部的page不等于目标page
      if (targetContainer.topPage != targetPage) {
        // Container执行popUntil，直到targetPage
        Future<void>.delayed(
            const Duration(milliseconds: 50),
            () => targetContainer?.navigator
                ?.popUntil(ModalRoute.withName(targetPage!.name!)));
      }
    } else {
      // 顶部Container执行popUntil，直到targetPage
      topContainer?.navigator?.popUntil(ModalRoute.withName(targetPage!.name!));
    }
  }
  
  // pop 页面
  Future<bool> pop(
      {String? uniqueId, Object? result, bool onBackPressed = false}) async {
    // 没有顶部的 container 直接返回false
    if (topContainer == null) return false;
    BoostContainer? container;
    // 如果有指定的uniqueId，则移除指定的uniqueId
    if (uniqueId != null) {
      // 找到对应的contianer
      container = _findContainerByUniqueId(uniqueId);
      if (container == null) {
        Logger.error('uniqueId=$uniqueId not found');
        return false;
      }
      // 如果移除的页面不是顶部页面
      if (container != topContainer) {
        //执行页面回调
        _completePendingResultIfNeeded(container.pageInfo.uniqueId,
            result: result);
        // native 执行页面的 pop（页面） 或者 dismiss（模态）
        await _removeContainer(container);
        return true;
      }
    } else {
      container = topContainer;
    }

    // 1.If uniqueId == null,indicate we simply call BoostNavigaotor.pop(),
    // so we call navigator?.maybePop();
    // 2.If uniqueId is topPage's uniqueId, so we navigator?.maybePop();
    // 3.If uniqueId is not topPage's uniqueId, so we will remove an existing
    // page in container.
    // 1. 如果 uniqueId == null，表示我们只是调用 BoostNavigator.pop()，所以调用 navigator?.maybePop();
    // 2. 如果 uniqueId 是最上面的页面的 uniqueId，那么我们调用 navigator?.maybePop();
    // 3. 如果 uniqueId 不是最上面的页面的 uniqueId，那么我们将移除容器中的一个现有页面。
    String? targetPage = uniqueId;
    final String topPage = container!.pages.last.pageInfo.uniqueId!;
    // 如果uniqueId为空，或者移除的就是最顶部的页面
    if (uniqueId == null || uniqueId == topPage) {
      // handled表示为当前是否可以执行返回
      final handled = onBackPressed
          ? await _performBackPressed(container, result)
          : container.navigator?.canPop();
      if (handled != null) {
        // 如果handled返回的是false
        if (!handled) {
          assert(container.pageInfo.withContainer!);
          final params = CommonParams()
            ..pageName = container.pageInfo.pageName
            ..uniqueId = container.pageInfo.uniqueId
            ..arguments = ((result is Map<String, dynamic>)
                ? result
                : <String, dynamic>{});
          // native侧执行页面pop
          await nativeRouterApi.popRoute(params);
          // 目标页面,如果不是传入id对应的页面，就是顶部页面
          targetPage = targetPage ?? topPage;
        } else {
          // 不是点击返回
          if (!onBackPressed) {
            // 执行pop操作
            container.navigator!.pop(result);
          }

          if (topPage != container.pages.last.pageInfo.uniqueId!) {
            // 1. Popped out pages pushed by FlutterBoost, including internal routes
            // 1. 弹出由 FlutterBoost push的页面，包括内部路由；如果不是传入id对应的页面，就是顶部页面
            targetPage = targetPage ?? topPage;
          } else {
            // 2. Popped out route pushed by `Navigator`, for example, showDialog
            // 2. 弹出由 Navigator push的路由，例如，showDialog
            assert(targetPage == null);
          }
        }
      }
    } else {
      // 移除一个内部page
      final page = container.pages
          .singleWhereOrNull((entry) => entry.pageInfo.uniqueId == uniqueId);
      container.removePage(page);
    }
    
    //执行页面回调
    _completePendingResultIfNeeded(targetPage, result: result);
    Logger.log('pop container, uniqueId=$uniqueId, result:$result, $container');
    return true;
  }
  
  //执行自定义返回操作
  Future<bool> _performBackPressed(
      BoostContainer container, Object? result) async {
    // 如果当前
    if (container.backPressedHandler != null) {
      container.backPressedHandler!.call();
      return true;
    } else {
      //否则，执行当前navigator的maybePop方法，返回当前页面是否可以执行pop操作
      return (await container.navigator?.maybePop(result))!;
    }
  }
  
  // 移除当前容器
  Future<void> _removeContainer(BoostContainer container) async {
    if (container.pageInfo.withContainer!) {
      Logger.log('_removeContainer ,  uniqueId=${container.pageInfo.uniqueId}');
      final params = CommonParams()
        ..pageName = container.pageInfo.pageName
        ..uniqueId = container.pageInfo.uniqueId
        ..arguments = container.pageInfo.arguments;
      return await _nativeRouterApi.popRoute(params);
    }
  }
  
  // 回到前台
  void onForeground() {
    if (topContainer != null) {
      BoostLifecycleBinding.instance.appDidEnterForeground(topContainer!);
    }
  }

  // 退到后台
  void onBackground() {
    if (topContainer != null) {
      BoostLifecycleBinding.instance.appDidEnterBackground(topContainer!);
    }
  }

  BoostContainer? _findContainerByUniqueId(String? uniqueId) {
    //Because first page can be removed from container.
    // 因为第一个页面可能会从容器中移除
    //So we find id in container's PageInfo
    //所以我们在容器的 PageInfo 中查找 ID
    //If we can't find a container matching this id,
    //如果找不到匹配此 ID 的容器
    //we will traverse all pages in all containers
    //我们将遍历所有容器中的所有页面
    //to find the page matching this id,and return its container
    //以查找匹配此 ID 的页面，并返回其容器
    //If we can't find any container or page matching this id,we return null
    // 如果找不到任何匹配此 ID 的容器或页面，我们将返回 null
    
    // 先containers层级找一遍，看看有没有对于的BoostContainer
    var result = _containers
        .singleWhereOrNull((element) => element.pageInfo.uniqueId == uniqueId);

    if (result != null) {
      return result;
    }
    
    // 再看看container对于的page层面有没有对应的页面
    return _containers.singleWhereOrNull((element) =>
        element.pages.any((element) => element.pageInfo.uniqueId == uniqueId));
  }
  
  // 通过uniqueId移除container
  void remove(String? uniqueId) {
    if (uniqueId == null) {
      return;
    }

    final container = _findContainerByUniqueId(uniqueId);
    if (container != null) {
      _containers.remove(container);
      BoostLifecycleBinding.instance.containerDidPop(container, topContainer);

      //remove the overlayEntry matching this container
      refreshOnRemove(container);
    } else {
      for (var container in _containers) {
        final page = container.pages
            .singleWhereOrNull((entry) => entry.pageInfo.uniqueId == uniqueId);
        container.removePage(page);
      }
    }
    Logger.log('remove,  uniqueId=$uniqueId, $_containers');
  }
  
  // 等待native页面结果
  Future<T> pendNativeResult<T extends Object?>(String? pageName) {
    final completer = Completer<T>();
    final initiatorPage = topContainer?.topPage.pageInfo.uniqueId;
    final key = '$initiatorPage#$pageName';
    _pendingResult[key] = completer;
    _nativePageKeys.add(key);
    Logger.log('pendNativeResult, key:$key, size:${_pendingResult.length}');
    return completer.future;
  }

  /// In boost's native side, should avoid calling this method when an outer_route's flutter page
  /// pops back to previous outer_route's flutter page.
  /// 在 Boost 的原生端，应该避免在外部路由的 Flutter 页面弹回到之前的外部路由的 Flutter 页面时调用此方法。
  void onNativeResult(CommonParams params) {
    final key = _topNativePage;
    _nativePageKeys.remove(key);
    if (_pendingResult.containsKey(key)) {
      _pendingResult[key]!.complete(params.arguments);
      _pendingResult.remove(key);
    }
    Logger.log('onNativeResult, key:$key, result:${params.arguments}');
  }
  
  // 执行flutter侧的页面push时候的等待回调
  void _completePendingResultIfNeeded<T extends Object?>(String? uniqueId,
      {T? result}) {
    if (uniqueId != null && _pendingResult.containsKey(uniqueId)) {
      _pendingResult[uniqueId]!.complete(result ?? {});
      _pendingResult.remove(uniqueId);
    }
  }

  void onContainerShow(CommonParams params) {
    final container = _findContainerByUniqueId(params.uniqueId);
    if (container != null) {
      BoostLifecycleBinding.instance.containerDidShow(container);
    }
  }

  void onContainerHide(CommonParams params) {
    final container = _findContainerByUniqueId(params.uniqueId);
    if (container != null) {
      BoostLifecycleBinding.instance.containerDidHide(container);
    }
  }

  ///
  ///Methods below are about Custom events with native side
  ///以下方法涉及与本地端的自定义事件
  ///

  ///Calls when Native send event to flutter(here)
  /// 当native发送event到flutter侧
  void onReceiveEventFromNative(CommonParams params) {
    //Get the name and args from native
    // 
    var key = params.key!;
    Map args = params.arguments ?? <String, Object>{};

    //Get all of listeners matching this key
    // 返回key对应的所有监听器
    final listeners = _listenersTable[key];

    if (listeners == null) return;

    for (final listener in listeners) {
      listener(key, args);
    }
  }

  ///Add event listener in flutter side with a [key] and [listener]
  /// 使用 [key] 和 [listener]在flutter侧添加监听
  VoidCallback addEventListener(String key, EventListener listener) {
    var listeners = _listenersTable[key];
    if (listeners == null) {
      listeners = [];
      _listenersTable[key] = listeners;
    }

    listeners.add(listener);

    return () {
      listeners!.remove(listener);
    };
  }

  ///Interal methods below
  /// 返回顶部页面的pageinfo,这是一个内部方法
  PageInfo? getTopPageInfo() {
    return topContainer?.topPage.pageInfo;
  }
  
  // 返回页面总数，包括container内的子页面也要统计
  int pageSize() {
    var count = 0;
    for (var container in _containers) {
      count += container.numPages();
    }
    return count;
  }

  ///
  ///======== refresh method below ===============
  /// 以下是刷新方法
  ///
  
  // 将container添加到Overlay最顶层
  void refreshOnPush(BoostContainer container) {
    // 将container插入到Overlay最顶部
    ContainerOverlay.instance.refreshSpecificOverlayEntries(
        container, BoostSpecificEntryRefreshMode.add);
    assert(() {
      _saveStackForHotRestart();
      return true;
    }());
  }
  
  // 将container添加到Overlay移除
  void refreshOnRemove(BoostContainer container) {
    ContainerOverlay.instance.refreshSpecificOverlayEntries(
        container, BoostSpecificEntryRefreshMode.remove);
    assert(() {
      _saveStackForHotRestart();
      return true;
    }());
  }
  
   // 将container移动到Overlay最顶层
  void refreshOnMoveToTop(BoostContainer container) {
    ContainerOverlay.instance.refreshSpecificOverlayEntries(
        container, BoostSpecificEntryRefreshMode.moveToTop);
    assert(() {
      _saveStackForHotRestart();
      return true;
    }());
  }
}

// bosst 页面，BoostPage 继承 Page，Page 继承 RouteSettings
// ignore: must_be_immutable
class BoostPage<T> extends Page<T> {
  BoostPage._({LocalKey? key, required this.pageInfo})
      : super(
            key: key, name: pageInfo.pageName, arguments: pageInfo.arguments) {
   // 根据 RouteSettings 信息，得到一个Route
    _route = BoostNavigator.instance.routeFactory(this, pageInfo.uniqueId)
        as Route<T>?;
    assert(_route != null,
        "Oops! Route name is not registered: '${pageInfo.pageName}'.");
  }
  final PageInfo pageInfo;

  factory BoostPage.create(PageInfo pageInfo) {
    return BoostPage._(key: UniqueKey(), pageInfo: pageInfo);
  }

  Route<T>? _route;

  Route<T>? get route => _route;

  /// A future that completes when this page is popped.
  /// 当前page，执行pop时候的future
  Future<T> get popped => _popCompleter.future;
  final Completer<T> _popCompleter = Completer<T>();

  void didComplete(T result) {
    if (!_popCompleter.isCompleted) {
      _popCompleter.complete(result);
    }
  }

  @override
  String toString() => '${objectRuntimeType(this, 'BoostPage')}(name:$name,'
      ' uniqueId:${pageInfo.uniqueId}, arguments:$arguments)';

  @override
  Route<T> createRoute(BuildContext context) {
    return _route!;
  }
}

// BoostNavigator 观察者，就是观察 Navigator 的行为
class BoostNavigatorObserver extends NavigatorObserver {
  BoostNavigatorObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    //handle internal route but ignore dialog or abnormal route.
    //otherwise, the normal page will be affected.
    // 处理内部路由，但是忽略dialog和abnormal路由，否则，常规页面可能会受影响
    if (previousRoute != null && route.settings.name != null) {
      BoostLifecycleBinding.instance.routeDidPush(route, previousRoute);
    }

    final navigatorObserverList =
        BoostLifecycleBinding.instance.navigatorObserverList;
    if (navigatorObserverList.isNotEmpty) {
      for (var observer in navigatorObserverList) {
        observer.didPush(route, previousRoute);
      }
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && route.settings.name != null) {
      BoostLifecycleBinding.instance.routeDidPop(route, previousRoute);
    }

    final navigatorObserverList =
        BoostLifecycleBinding.instance.navigatorObserverList;
    if (navigatorObserverList.isNotEmpty) {
      for (var observer in navigatorObserverList) {
        observer.didPop(route, previousRoute);
      }
    }

    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final navigatorObserverList =
        BoostLifecycleBinding.instance.navigatorObserverList;
    if (navigatorObserverList.isNotEmpty) {
      for (var observer in navigatorObserverList) {
        observer.didRemove(route, previousRoute);
      }
    }
    super.didRemove(route, previousRoute);
    BoostLifecycleBinding.instance.routeDidRemove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final navigatorObserverList =
        BoostLifecycleBinding.instance.navigatorObserverList;
    if (navigatorObserverList.isNotEmpty) {
      for (var observer in navigatorObserverList) {
        observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);
      }
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(
      Route<dynamic> route, Route<dynamic>? previousRoute) {
    final navigatorObserverList =
        BoostLifecycleBinding.instance.navigatorObserverList;
    if (navigatorObserverList.isNotEmpty) {
      for (var observer in navigatorObserverList) {
        observer.didStartUserGesture(route, previousRoute);
      }
    }
    super.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    final navigatorObserverList =
        BoostLifecycleBinding.instance.navigatorObserverList;
    if (navigatorObserverList.isNotEmpty) {
      for (var observer in navigatorObserverList) {
        observer.didStopUserGesture();
      }
    }
    super.didStopUserGesture();
  }
}
