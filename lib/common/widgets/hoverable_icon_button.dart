import 'package:flutter/material.dart';

class HoverableIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double? iconSize;
  final Color? hoverColor;
  final EdgeInsetsGeometry? padding;

  const HoverableIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.iconSize,
    this.hoverColor,
    this.padding,
  });

  @override
  State<HoverableIconButton> createState() => _HoverableIconButtonState();
}

class _HoverableIconButtonState extends State<HoverableIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _isHovered ? (widget.hoverColor ?? Colors.grey.withOpacity(0.2)) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(widget.icon, color: widget.iconColor ?? const Color(0xFFD4D4D4), size: widget.iconSize ?? 20),
        ),
      ),
    );
  }
}
