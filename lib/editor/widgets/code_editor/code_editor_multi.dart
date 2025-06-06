import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/rainbow.dart';
import 'package:trayce/common/types.dart';
import 'package:trayce/editor/widgets/code_editor/auto_complete_list.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_context_menu.dart';
import 'package:trayce/editor/widgets/code_editor/find_replace.dart';

class MultiLineCodeEditor extends StatefulWidget {
  final CodeLineEditingController controller;
  final ScrollController? verticalScroller;
  final ScrollController? horizontalScroller;
  final Map<Type, Action<Intent>>? shortcutOverrideActions;
  final Border? border;
  final KeyCallback? keyCallback;
  final VoidCallback? onFocusChange;

  const MultiLineCodeEditor({
    super.key,
    required this.controller,
    this.verticalScroller,
    this.horizontalScroller,
    this.shortcutOverrideActions,
    this.border,
    this.keyCallback,
    this.onFocusChange,
  });

  @override
  State<MultiLineCodeEditor> createState() => _MultiLineCodeEditorState();
}

class _MultiLineCodeEditorState extends State<MultiLineCodeEditor> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.onKeyEvent = widget.keyCallback;
    _focusNode.addListener(() {
      widget.onFocusChange?.call();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeAutocomplete(
      viewBuilder: (context, notifier, onSelected) {
        return DefaultCodeAutocompleteListView(
          notifier: notifier,
          onSelected: onSelected,
        );
      },
      promptsBuilder: DefaultCodeAutocompletePromptsBuilder(language: langJson),
      child: CodeEditor(
        controller: widget.controller,
        focusNode: _focusNode,
        findBuilder: (context, controller, readOnly) {
          controller.findInputFocusNode.onKeyEvent = (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              controller.close();
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              controller.nextMatch();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          };
          return CodeFindPanelView(controller: controller, readOnly: readOnly);
        },
        border: widget.border ?? Border.all(width: 0.0),
        style: CodeEditorStyle(
          fontFamily: "monospace",
          textColor: const Color(0xFFD4D4D4),
          codeTheme: CodeHighlightTheme(
            languages: {'json': CodeHighlightThemeMode(mode: langJson)},
            theme: rainbowTheme,
          ),
        ),
        wordWrap: false,
        shortcutOverrideActions: widget.shortcutOverrideActions,
        scrollbarBuilder: (context, child, details) {
          return Scrollbar(
            controller: details.controller,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 6,
            child: child,
          );
        },
        indicatorBuilder: (
          context,
          editingController,
          chunkController,
          notifier,
        ) {
          return Row(
            children: [
              DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
              ),
              DefaultCodeChunkIndicator(
                width: 20,
                controller: chunkController,
                notifier: notifier,
              ),
            ],
          );
        },
        toolbarController: const ContextMenuControllerImpl(),
      ),
    );
  }
}
