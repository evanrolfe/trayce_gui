import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/widgets/code_editor/auto_complete_list.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_context_menu.dart';

class FormTableInput extends StatefulWidget {
  final CodeLineEditingController controller;
  final ScrollController? verticalScroller;
  final ScrollController? horizontalScroller;
  final Map<Type, Action<Intent>>? shortcutOverrideActions;
  final VoidCallback? onEnterPressed;
  final FocusNode? focusNode;
  final BoxDecoration? decoration;
  final bool readOnly;
  const FormTableInput({
    required super.key,
    required this.controller,
    this.verticalScroller,
    this.horizontalScroller,
    this.shortcutOverrideActions,
    this.onEnterPressed,
    this.focusNode,
    this.decoration,
    this.readOnly = false,
  });

  @override
  State<FormTableInput> createState() => _FormTableInputState();
}

class _FormTableInputState extends State<FormTableInput> {
  late final FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    final eventBus = context.read<EventBus>();
    eventBus.on<EditorInputFocused>().listen((event) {
      if (event.key != widget.key &&
          widget.controller.selection.baseOffset != widget.controller.selection.extentOffset) {
        widget.controller.selection = CodeLineSelection.collapsed(
          index: widget.controller.selection.baseIndex,
          offset: widget.controller.selection.baseOffset,
        );
        return;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    final eventBus = context.read<EventBus>();
    final key = widget.key ?? const Key('default');
    eventBus.fire(EditorInputFocused(key));
  }

  Color _getBackgroundColor() {
    if (_isHovered) {
      return backgroundColor;
    }
    return inputBackgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: CodeAutocomplete(
          viewBuilder: (context, notifier, onSelected) {
            return DefaultCodeAutocompleteListView(notifier: notifier, onSelected: onSelected);
          },
          promptsBuilder: DefaultCodeAutocompletePromptsBuilder(language: langDart),
          child: CodeEditor(
            controller: widget.controller,
            readOnly: widget.readOnly,
            scrollController: CodeScrollController(
              verticalScroller:
                  widget.verticalScroller ?? ScrollController(initialScrollOffset: 0, keepScrollOffset: false),
              horizontalScroller:
                  widget.horizontalScroller ?? ScrollController(initialScrollOffset: 0, keepScrollOffset: false),
            ),
            // border: _getDynamicBorder(),
            style: CodeEditorStyle(
              fontFamily: "monospace",
              textColor: const Color(0xFFD4D4D4),
              backgroundColor: _getBackgroundColor(),
            ),
            wordWrap: false,
            shortcutOverrideActions: widget.shortcutOverrideActions,
            focusNode: _focusNode,
            scrollbarBuilder: (context, child, details) {
              return Scrollbar(
                controller: details.controller,
                thumbVisibility: false,
                trackVisibility: false,
                thickness: 0,
                child: child,
              );
            },
            toolbarController: const ContextMenuControllerImpl(),
          ),
        ),
      ),
    );
  }
}
