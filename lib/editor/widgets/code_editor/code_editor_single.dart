import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:trayce/editor/widgets/code_editor/auto_complete_list.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_context_menu.dart';

class SingleLineCodeEditor extends StatefulWidget {
  final CodeLineEditingController controller;
  final ScrollController? verticalScroller;
  final ScrollController? horizontalScroller;
  final Map<Type, Action<Intent>>? shortcutOverrideActions;
  final VoidCallback? onTabPressed;
  final VoidCallback? onEnterPressed;
  final FocusNode? focusNode;
  final BoxDecoration? decoration;
  final VoidCallback? onSavePressed;
  final VoidCallback? onFocusChange;

  const SingleLineCodeEditor({
    super.key,
    required this.controller,
    this.verticalScroller,
    this.horizontalScroller,
    this.shortcutOverrideActions,
    this.onTabPressed,
    this.onEnterPressed,
    this.focusNode,
    this.decoration,
    this.onSavePressed,
    this.onFocusChange,
  });

  @override
  State<SingleLineCodeEditor> createState() => _SingleLineCodeEditorState();
}

class _SingleLineCodeEditorState extends State<SingleLineCodeEditor> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _focusNode.onKeyEvent = (node, event) {
      final isCmdPressed = (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);

      if (event.logicalKey == LogicalKeyboardKey.keyS && isCmdPressed) {
        widget.onSavePressed?.call();
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
        widget.onTabPressed?.call();
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onEnterPressed?.call();
        // Do not allow new line
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onFocusChange?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration,
      child: CodeAutocomplete(
        viewBuilder: (context, notifier, onSelected) {
          return DefaultCodeAutocompleteListView(notifier: notifier, onSelected: onSelected);
        },
        promptsBuilder: DefaultCodeAutocompletePromptsBuilder(language: langDart),
        child: CodeEditor(
          controller: widget.controller,
          scrollController: CodeScrollController(
            verticalScroller:
                widget.verticalScroller ?? ScrollController(initialScrollOffset: 0, keepScrollOffset: false),
            horizontalScroller:
                widget.horizontalScroller ?? ScrollController(initialScrollOffset: 0, keepScrollOffset: false),
          ),
          border: Border(
            left: BorderSide(color: const Color(0xFF474747), width: 0),
            top: BorderSide(color: const Color(0xFF474747), width: 0),
            right: BorderSide(color: const Color(0xFF474747), width: 0),
            bottom: BorderSide(color: const Color(0xFF474747), width: 0),
          ),
          style: const CodeEditorStyle(fontFamily: "monospace", textColor: Color(0xFFD4D4D4)),
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
    );
  }
}
