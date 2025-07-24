import 'package:re_editor/re_editor.dart';

class FormTableRow {
  final CodeLineEditingController keyController;
  final CodeLineEditingController valueController;
  final CodeLineEditingController contentTypeController;
  String? valueFile;
  bool checkboxState;
  bool checkboxStateSecret;
  bool newRow;
  String previousKeyText;
  String previousValueText;
  String previousContentTypeText;

  FormTableRow({
    required this.keyController,
    required this.valueController,
    required this.contentTypeController,
    required this.newRow,
    this.checkboxState = false,
    this.checkboxStateSecret = false,
    this.previousKeyText = '',
    this.previousValueText = '',
    this.previousContentTypeText = '',
    this.valueFile,
  });

  void dispose() {
    keyController.dispose();
    valueController.dispose();
    contentTypeController.dispose();
  }

  void swapWith(FormTableRow otherRow) {
    // Swap checkboxState
    final tempCheckboxState = checkboxState;
    checkboxState = otherRow.checkboxState;
    otherRow.checkboxState = tempCheckboxState;

    // Swap previousKeyText
    final tempPreviousKeyText = previousKeyText;
    previousKeyText = otherRow.previousKeyText;
    otherRow.previousKeyText = tempPreviousKeyText;

    // Swap previousValueText
    final tempPreviousValueText = previousValueText;
    previousValueText = otherRow.previousValueText;
    otherRow.previousValueText = tempPreviousValueText;

    // Swap previousContentTypeText
    final tempPreviousContentTypeText = previousContentTypeText;
    previousContentTypeText = otherRow.previousContentTypeText;
    otherRow.previousContentTypeText = tempPreviousContentTypeText;

    // Swap keyController.text
    final tempKeyText = keyController.text;
    keyController.text = otherRow.keyController.text;
    otherRow.keyController.text = tempKeyText;

    // Swap valueController.text
    final tempValueText = valueController.text;
    valueController.text = otherRow.valueController.text;
    otherRow.valueController.text = tempValueText;

    // Swap contentTypeController.text
    final tempContentTypeText = contentTypeController.text;
    contentTypeController.text = otherRow.contentTypeController.text;
    otherRow.contentTypeController.text = tempContentTypeText;

    // Swap valueFile
    final tempValueFile = valueFile;
    valueFile = otherRow.valueFile;
    otherRow.valueFile = tempValueFile;

    // Swap checkboxStateSecret
    final tempCheckboxStateSecret = checkboxStateSecret;
    checkboxStateSecret = otherRow.checkboxStateSecret;
    otherRow.checkboxStateSecret = tempCheckboxStateSecret;
  }

  bool isEmpty() {
    return keyController.text.isEmpty &&
        valueController.text.isEmpty &&
        contentTypeController.text.isEmpty &&
        valueFile == null &&
        !checkboxState &&
        !checkboxStateSecret;
  }

  void setEmpty() {
    keyController.text = '';
    valueController.text = '';
    contentTypeController.text = '';
    valueFile = null;
    checkboxState = false;
    checkboxStateSecret = false;
    previousKeyText = '';
    previousValueText = '';
  }
}
