import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/rainbow.dart';
import 'package:trayce/editor/auto_complete_list.dart';
import 'package:trayce/editor/code_editor_context_menu.dart';

class MultiLineCodeEditor extends StatelessWidget {
  final CodeLineEditingController controller;
  final ScrollController? verticalScroller;
  final ScrollController? horizontalScroller;
  final Map<Type, Action<Intent>>? shortcutOverrideActions;
  final Border? border;

  const MultiLineCodeEditor({
    super.key,
    required this.controller,
    this.verticalScroller,
    this.horizontalScroller,
    this.shortcutOverrideActions,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return CodeAutocomplete(
      viewBuilder: (context, notifier, onSelected) {
        return DefaultCodeAutocompleteListView(notifier: notifier, onSelected: onSelected);
      },
      promptsBuilder: DefaultCodeAutocompletePromptsBuilder(language: langJson),
      child: CodeEditor(
        controller: controller,
        scrollController: CodeScrollController(
          verticalScroller: verticalScroller ?? ScrollController(initialScrollOffset: 0, keepScrollOffset: false),
          horizontalScroller: horizontalScroller ?? ScrollController(initialScrollOffset: 0, keepScrollOffset: false),
        ),
        border: border ?? Border.all(width: 0.0),
        style: CodeEditorStyle(
          fontFamily: "monospace",
          textColor: const Color(0xFFD4D4D4),
          codeTheme: CodeHighlightTheme(
            languages: {'json': CodeHighlightThemeMode(mode: langJson)},
            theme: rainbowTheme,
          ),
        ),
        wordWrap: false,
        shortcutOverrideActions: shortcutOverrideActions,
        scrollbarBuilder: (context, child, details) {
          return Scrollbar(
            controller: details.controller,
            thumbVisibility: false,
            trackVisibility: false,
            thickness: 0,
            child: child,
          );
        },
        indicatorBuilder: (context, editingController, chunkController, notifier) {
          return Row(
            children: [
              DefaultCodeLineNumber(controller: editingController, notifier: notifier),
              DefaultCodeChunkIndicator(width: 20, controller: chunkController, notifier: notifier),
            ],
          );
        },
        toolbarController: const ContextMenuControllerImpl(),
      ),
    );
  }
}
