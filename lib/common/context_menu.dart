import 'package:flutter/material.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';

class CustomPopupMenuItem<T> extends PopupMenuItem<T> {
  const CustomPopupMenuItem({
    super.key,
    super.value,
    super.enabled = true,
    super.height = 30,
    super.padding = const EdgeInsets.symmetric(horizontal: 2),
    super.textStyle,
    super.mouseCursor,
    required super.child,
    super.onTap,
  });

  @override
  PopupMenuItemState<T, CustomPopupMenuItem<T>> createState() => _CustomPopupMenuItemState<T>();
}

class _CustomPopupMenuItemState<T> extends PopupMenuItemState<T, CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onTap?.call();
        },
        hoverColor: selectedMenuItemColor,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: 175,
          child: Align(alignment: Alignment.centerLeft, child: widget.child),
        ),
      ),
    );
  }
}
