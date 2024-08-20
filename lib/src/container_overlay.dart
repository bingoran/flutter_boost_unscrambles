// Copyright (c) 2019 Alibaba Group. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'boost_container.dart';
import 'logger.dart';

final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

/// The Entry refresh mode, which indicates different situation
/// boost 实例刷新模式
enum BoostSpecificEntryRefreshMode {
  ///Just add an new entry
  ///添加
  add,

  ///remove a specific entry from entries list
  ///移除
  remove,

  ///move an existing entry to top
  ///移动最在的entry到顶部
  moveToTop,
}

// Overlay 实体类
// 初始化的时候，将 BoostContainer 用 BoostContainerWidget 进行包裹
class ContainerOverlayEntry extends OverlayEntry {
  ContainerOverlayEntry(BoostContainer container)
      : containerUniqueId = container.pageInfo.uniqueId,
        super(
            builder: (ctx) => BoostContainerWidget(container: container),
            opaque: true,
            maintainState: true);

  /// This overlay's id, which is the same as the it's related container
  /// 这是 overlay id，与相关容器相同
  final String? containerUniqueId;

  @override
  String toString() {
    return 'ContainerOverlayEntry: containerId:$containerUniqueId';
  }
}

/// Creates a [ContainerOverlayEntry] for the given [BoostContainer].
/// 为给定的[BoostContainer]创建一个[ContainerOverlayEntry]
typedef ContainerOverlayEntryFactory = ContainerOverlayEntry Function(
    BoostContainer container);

class ContainerOverlay {
  ContainerOverlay._();

  static final ContainerOverlay instance = ContainerOverlay._();
  
  // 保存添加的ContainerOverlayEntry
  final List<ContainerOverlayEntry> _lastEntries = <ContainerOverlayEntry>[];

  static ContainerOverlayEntryFactory? _overlayEntryFactory;

  /// Sets a custom [ContainerOverlayEntryFactory].
  /// 设置自定义的[ContainerOverlayEntryFactory]
  static set overlayEntryFactory(ContainerOverlayEntryFactory entryFactory) {
    _overlayEntryFactory = entryFactory;
  }

  static ContainerOverlayEntryFactory get overlayEntryFactory {
    return _overlayEntryFactory ??=
        ((container) => ContainerOverlayEntry(container));
  }

  ///Refresh an specific entry instead of all of entries to enhance the performace
  ///刷新特定的条目而不是所有条目，以提高性能
  ///
  ///[container] : The container you want to operate, it is related with internal [OverlayEntry]
  ///[container]：您想要操作的容器，它与内部的 [OverlayEntry] 相关
  ///[mode] : The [BoostSpecificEntryRefreshMode] you want to choose
  ///[mode]：您想要选择的 [BoostSpecificEntryRefreshMode]
  void refreshSpecificOverlayEntries(
      BoostContainer container, BoostSpecificEntryRefreshMode mode) {
    // The |overlayState| is null if there is no widget in the tree
    // that matches this global key.
    //如果树中没有widget，则|overlayState|为null
    //匹配全局键。
    final overlayState = overlayKey.currentState;
    if (overlayState == null) {
      Logger.error('Oops, Failed to update overlay. mode=$mode, $container');
      return;
    }

    //deal with different situation
    //处理不同情况
    switch (mode) {
      case BoostSpecificEntryRefreshMode.add:
        // If there is an existing ContainerOverlayEntry in the list,we do nothing
        //如果列表中已经存在ContainerOverlayEntry，我们什么都不做
        final ContainerOverlayEntry? existingEntry =
            _findExistingEntry(container: container);
        if (existingEntry != null) {
          return;
        }

        // There is no existing entry in List.We can add an new Entry to list
        // list中不存在实体，添加
        final entry = overlayEntryFactory(container);
        _lastEntries.add(entry);

        // 将给定的条目插入到覆盖层中。
        // 如果 below 非空，则将条目插入到 below 下面。
        // 如果 above 非空，则将条目插入到 above 上面。
        // 否则，条目将插入到最上面。
        // 同时指定 above 和 below 是错误的。
        overlayState.insert(entry);
        break;
      case BoostSpecificEntryRefreshMode.remove:
        if (_lastEntries.isNotEmpty) {
          //Find the entry matching the container
          final entryToRemove = _lastEntries.singleWhere((element) {
            return element.containerUniqueId == container.pageInfo.uniqueId;
          });

          //remove from the list and overlay
          _lastEntries.remove(entryToRemove);
          entryToRemove.remove();
          // https://github.com/alibaba/flutter_boost/issues/1056
          // Ensure this frame is refreshed after schedule frame,
          // otherwise the PageState.dispose may not be called
          SchedulerBinding.instance.scheduleWarmUpFrame();
        }
        break;
      case BoostSpecificEntryRefreshMode.moveToTop:
        final ContainerOverlayEntry? existingEntry =
            _findExistingEntry(container: container);

        if (existingEntry == null) {
          /// If there is no entry in the list,we add it in list
          refreshSpecificOverlayEntries(
              container, BoostSpecificEntryRefreshMode.add);
        } else {
          /// we take the existingEntry out and move it to top
          //remove the entry from list and overlay
          //and insert it to list'top and overlay 's top
          _lastEntries.remove(existingEntry);
          _lastEntries.add(existingEntry);
          existingEntry.remove();
          overlayState.insert(existingEntry);
        }
        break;
    }
  }

  /// Return the result whether we can find a [ContainerOverlayEntry] matching this [container]
  /// If no entry matches this id,return null
  ///返回结果是否可以找到与[container]匹配的[ContainerOverlayEntry]
  ///如果没有匹配此id的条目，则返回null
  ContainerOverlayEntry? _findExistingEntry(
      {required BoostContainer container}) {
    return _lastEntries.singleWhereOrNull(
        (element) => element.containerUniqueId == container.pageInfo.uniqueId);
  }
}
