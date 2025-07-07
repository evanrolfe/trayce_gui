import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/widgets/code_editor/auto_complete_list.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_context_menu.dart';

class SingleLineCodeEditor extends StatefulWidget {
  final CodeLineEditingController controller;
  final ScrollController? verticalScroller;
  final ScrollController? horizontalScroller;
  final Map<Type, Action<Intent>>? shortcutOverrideActions;
  final VoidCallback? onEnterPressed;
  final FocusNode? focusNode;
  final BoxDecoration? decoration;
  final Border? border;
  const SingleLineCodeEditor({
    required super.key,
    required this.controller,
    this.verticalScroller,
    this.horizontalScroller,
    this.shortcutOverrideActions,
    this.onEnterPressed,
    this.focusNode,
    this.decoration,
    this.border,
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
          border: widget.border,
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
