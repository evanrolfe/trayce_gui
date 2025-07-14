import 'package:trayce/editor/widgets/common/form_table_row.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';

abstract interface class FormTableControllerI {
  List<FormTableRow> rows();
  EditorFocusManager focusManager();
  int selectedRowIndex();
  void setSelectedRowIndex(int value);
  void deleteRow(int index);
  void uploadValueFile(int index);
  void dispose();

  void setCheckboxState(int index, bool value);
  void setCheckboxStateSecret(int index, bool value);
}
