import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/rainbow.dart';
import 'package:trayce/common/events.dart';
import 'package:trayce/editor/widgets/code_editor/auto_complete_list.dart';
import 'package:trayce/editor/widgets/code_editor/code_editor_context_menu.dart';
import 'package:trayce/editor/widgets/code_editor/find_replace.dart';

class MultiLineCodeEditor extends StatefulWidget {
  final CodeLineEditingController controller;
  final ScrollController? verticalScroller;
  final ScrollController? horizontalScroller;
  final Map<Type, Action<Intent>>? shortcutOverrideActions;
  final Border? border;
  final VoidCallback? onFocusChange;
  final FocusNode focusNode;

  const MultiLineCodeEditor({
    super.key,
    required this.controller,
    this.verticalScroller,
    this.horizontalScroller,
    this.shortcutOverrideActions,
    this.border,
    this.onFocusChange,
    required this.focusNode,
  });

  @override
  State<MultiLineCodeEditor> createState() => _MultiLineCodeEditorState();
}

class _MultiLineCodeEditorState extends State<MultiLineCodeEditor> {
  late final FocusNode _focusNode;
  @override
  void initState() {
    super.initState();

    _focusNode = widget.focusNode;
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
    return CodeAutocomplete(
      viewBuilder: (context, notifier, onSelected) {
        return DefaultCodeAutocompleteListView(notifier: notifier, onSelected: onSelected);
      },
      promptsBuilder: DefaultCodeAutocompletePromptsBuilder(language: langJson),
      child: CodeEditor(
        controller: widget.controller,
        focusNode: widget.focusNode,
        findBuilder: (context, controller, readOnly) {
          controller.findInputFocusNode.onKeyEvent = (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              controller.close();
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
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
