import 'package:flutter/material.dart';

class AutoScrollListView extends StatefulWidget {
  final ScrollController controller;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final int initialIndex;
  final Axis scrollDirection;

  const AutoScrollListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.itemCount,
    this.initialIndex = 0,
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<StatefulWidget> createState() => _AutoScrollListViewState();
}

class _AutoScrollListViewState extends State<AutoScrollListView> {
  late final List<GlobalKey> _keys;

  @override
  void initState() {
    _keys = List.generate(widget.itemCount, (index) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScroll();
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AutoScrollListView oldWidget) {
    if (widget.itemCount > oldWidget.itemCount) {
      _keys.addAll(List.generate(widget.itemCount - oldWidget.itemCount, (index) => GlobalKey()));
    } else if (widget.itemCount < oldWidget.itemCount) {
      _keys.sublist(oldWidget.itemCount - widget.itemCount);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScroll();
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = [];
    for (int i = 0; i < widget.itemCount; i++) {
      widgets.add(Container(
        key: _keys[i],
        child: widget.itemBuilder(context, i),
      ));
    }
    return SingleChildScrollView(
      controller: widget.controller,
      scrollDirection: widget.scrollDirection,
      child: isHorizontal
          ? Row(
              children: widgets,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            ),
    );
  }

  void _autoScroll() {
    final ScrollController controller = widget.controller;
    if (!controller.hasClients) {
      return;
    }
    if (controller.position.maxScrollExtent == 0) {
      return;
    }
    double pre = 0;
    double cur = 0;
    for (int i = 0; i < _keys.length; i++) {
      final RenderObject? obj = _keys[i].currentContext?.findRenderObject();
      if (obj == null || obj is! RenderBox) {
        continue;
      }
      if (isHorizontal) {
        double width = obj.size.width;
        if (i == widget.initialIndex) {
          cur = pre + width;
          break;
        }
        pre += width;
      } else {
        double height = obj.size.height;
        if (i == widget.initialIndex) {
          cur = pre + height;
          break;
        }
        pre += height;
      }
    }
    if (pre == cur) {
      return;
    }
    if (pre < widget.controller.offset) {
      controller.jumpTo(pre - 1);
    } else if (cur > controller.offset + controller.position.viewportDimension) {
      controller.jumpTo(cur - controller.position.viewportDimension);
    }
  }

  bool get isHorizontal => widget.scrollDirection == Axis.horizontal;
}
