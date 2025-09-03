import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/dropdown_style.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/common/widgets/hoverable_icon_button.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/variable.dart';
import 'package:trayce/editor/repo/collection_repo.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:trayce/editor/repo/folder_repo.dart';
import 'package:trayce/editor/widgets/common/form_table.dart';
import 'package:trayce/editor/widgets/common/inline_tab_bar.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_basic_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_basic_form.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_bearer_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_bearer_form.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_not_implemented.dart';
import 'package:trayce/editor/widgets/flow_editor_http/focus_manager.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_headers_controller.dart';
import 'package:trayce/editor/widgets/flow_editor_http/form_vars_controller.dart';

Future<void> showNodeSettingsModal(BuildContext context, ExplorerNode node) {
  return showDialog(context: context, builder: (dialogContext) => NodeSettingsModal(node: node));
}

class NodeSettingsModal extends StatefulWidget {
  final ExplorerNode node;
  const NodeSettingsModal({super.key, required this.node});

  @override
  State<NodeSettingsModal> createState() => _NodeSettingsModalState();
}

class _NodeSettingsModalState extends State<NodeSettingsModal> with TickerProviderStateMixin {
  late TabController _tabController;
  late FormHeadersController _headersController;
  late FormVarsController _varsController;
  late AuthBasicControllerI _authBasicController;
  late AuthBearerControllerI _authBearerController;
  late EditorFocusManager _focusManager;
  int _selectedAuthTypeIndex = 0;

  late String _title;

  static const List<String> _tabTitles = ['Headers', 'Auth', 'Variables'];
  static const List<String> _authTypeOptions = ['No Auth', 'Basic Auth', 'Bearer Token', 'Digest', 'OAuth2', 'WSSE'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // This will trigger a rebuild when the tab changes
    });

    final config = context.read<ConfigRepo>().get();
    final eventBus = context.read<EventBus>();
    final filePicker = context.read<FilePickerI>();
    _focusManager = EditorFocusManager(eventBus, const ValueKey('node_settings_modal'));

    if (widget.node is FolderNode) {
      _title = 'Folder Settings';
    } else if (widget.node is CollectionNode) {
      _title = 'Collection Settings';
    }
    // Headers
    List<Header> headers = [];
    if (widget.node is FolderNode) {
      headers = (widget.node as FolderNode).folder.headers;
    } else if (widget.node is CollectionNode) {
      headers = (widget.node as CollectionNode).collection.headers;
    }

    _headersController = FormHeadersController(
      initialRows: headers,
      onStateChanged: () => setState(() {}),
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
    );

    // Vars
    List<Variable> vars = [];
    if (widget.node is FolderNode) {
      vars = (widget.node as FolderNode).folder.requestVars;
    } else if (widget.node is CollectionNode) {
      vars = (widget.node as CollectionNode).collection.requestVars;
    }

    _varsController = FormVarsController(
      onStateChanged: () => setState(() {}),
      initialRows: vars,
      config: config,
      focusManager: _focusManager,
      eventBus: eventBus,
      filePicker: filePicker,
      tableFormType: TableForm.requestVars,
    );

    // Auth Type
    AuthType authType = AuthType.none;
    if (widget.node is FolderNode) {
      authType = (widget.node as FolderNode).folder.authType;
    } else if (widget.node is CollectionNode) {
      authType = (widget.node as CollectionNode).collection.authType;
    }

    switch (authType) {
      case AuthType.none:
        _selectedAuthTypeIndex = 0;
      case AuthType.basic:
        _selectedAuthTypeIndex = 1;
      case AuthType.bearer:
        _selectedAuthTypeIndex = 2;
      case AuthType.digest:
        _selectedAuthTypeIndex = 3;
      case AuthType.oauth2:
        _selectedAuthTypeIndex = 4;
      case AuthType.wsse:
        _selectedAuthTypeIndex = 5;
      default:
        _selectedAuthTypeIndex = 0;
    }

    // Auth Basic
    if (widget.node is FolderNode) {
      _authBasicController = AuthBasicControllerFolder((widget.node as FolderNode).folder);
    } else if (widget.node is CollectionNode) {
      _authBasicController = AuthBasicControllerCollection((widget.node as CollectionNode).collection);
    }

    // Auth Bearer
    if (widget.node is FolderNode) {
      _authBearerController = AuthBearerControllerFolder((widget.node as FolderNode).folder);
    } else if (widget.node is CollectionNode) {
      _authBearerController = AuthBearerControllerCollection((widget.node as CollectionNode).collection);
    }
  }

  Future<void> _onSave() async {
    // Set the headers
    if (widget.node is FolderNode) {
      (widget.node as FolderNode).folder.authType = AuthType.basic;
      (widget.node as FolderNode).folder.headers = _headersController.getHeaders();
    } else if (widget.node is CollectionNode) {
      (widget.node as CollectionNode).collection.headers = _headersController.getHeaders();
    }

    // Set the variables
    if (widget.node is FolderNode) {
      (widget.node as FolderNode).folder.requestVars = _varsController.getVars();
    } else if (widget.node is CollectionNode) {
      (widget.node as CollectionNode).collection.requestVars = _varsController.getVars();
    }

    // Set the auth
    AuthType authType = switch (_selectedAuthTypeIndex) {
      0 => AuthType.none,
      1 => AuthType.basic,
      2 => AuthType.bearer,
      3 => AuthType.digest,
      4 => AuthType.oauth2,
      5 => AuthType.wsse,
      _ => AuthType.none,
    };

    if (widget.node is FolderNode) {
      (widget.node as FolderNode).folder.authType = authType;
      (widget.node as FolderNode).folder.authBasic = _authBasicController.getAuth();
      (widget.node as FolderNode).folder.authBearer = _authBearerController.getAuth();
    } else if (widget.node is CollectionNode) {
      (widget.node as CollectionNode).collection.authType = authType;
      (widget.node as CollectionNode).collection.authBasic = _authBasicController.getAuth();
      (widget.node as CollectionNode).collection.authBearer = _authBearerController.getAuth();
    }

    // Save
    if (widget.node is CollectionNode) {
      context.read<CollectionRepo>().save((widget.node as CollectionNode).collection);
    }
    if (widget.node is FolderNode) {
      context.read<FolderRepo>().save((widget.node as FolderNode).folder);
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headersController.dispose();
    _varsController.dispose();
    _authBasicController.dispose();
    _authBearerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_authTypeOptions[_selectedAuthTypeIndex] == _authTypeOptions[0]) {
      _selectedAuthTypeIndex = 0;
    } else if (_authTypeOptions[_selectedAuthTypeIndex] == _authTypeOptions[1]) {
      _selectedAuthTypeIndex = 1;
    } else if (_authTypeOptions[_selectedAuthTypeIndex] == _authTypeOptions[2]) {
      _selectedAuthTypeIndex = 2;
    } else if (_authTypeOptions[_selectedAuthTypeIndex] == _authTypeOptions[3]) {
      _selectedAuthTypeIndex = 3;
    } else if (_authTypeOptions[_selectedAuthTypeIndex] == _authTypeOptions[4]) {
      _selectedAuthTypeIndex = 4;
    } else if (_authTypeOptions[_selectedAuthTypeIndex] == _authTypeOptions[5]) {
      _selectedAuthTypeIndex = 5;
    }

    return Dialog(
      backgroundColor: lightBackgroundColor,
      shape: dialogShape,
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  HoverableIconButton(onPressed: () => Navigator.of(context).pop(), icon: Icons.close),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                animationDuration: Duration.zero,
                child: Column(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border(top: BorderSide(width: 1, color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InlineTabBar(
                              controller: _tabController,
                              tabTitles: _tabTitles,
                              focusNode: FocusNode(),
                            ),
                          ),
                          if (_tabController.index == 1) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 120,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF474747), width: 0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButton2<String>(
                                key: const Key('flow_editor_node_settings_auth_type_dropdown'),
                                focusNode: FocusNode(),
                                value: _authTypeOptions[_selectedAuthTypeIndex],
                                underline: Container(),
                                dropdownStyleData: DropdownStyleData(
                                  decoration: dropdownDecoration,
                                  width: 150,
                                  openInterval: Interval(0.0, 0.0),
                                ),
                                buttonStyleData: ButtonStyleData(
                                  padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
                                ),
                                menuItemStyleData: menuItemStyleData,
                                iconStyleData: iconStyleData,
                                style: textFieldStyle,
                                isExpanded: true,
                                items:
                                    _authTypeOptions.map((String format) {
                                      return DropdownMenuItem<String>(
                                        value: format,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(format),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == null) return;
                                    _selectedAuthTypeIndex = _authTypeOptions.indexOf(value);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: backgroundColor,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // -----------------------------------------------------------
                            // Headers Tab
                            // -----------------------------------------------------------
                            SingleChildScrollView(
                              child: FormTable(
                                controller: _headersController,
                                columns: [
                                  FormTableColumn.enabled,
                                  FormTableColumn.key,
                                  FormTableColumn.value,
                                  FormTableColumn.delete,
                                ],
                              ),
                            ),
                            // -----------------------------------------------------------
                            // Auth Tab
                            // -----------------------------------------------------------
                            IndexedStack(
                              index: _selectedAuthTypeIndex,
                              children: [
                                // No Body
                                Center(
                                  child: Text('No Auth', style: TextStyle(color: Color(0xFF808080), fontSize: 16)),
                                ),
                                // Basic Auth
                                AuthBasicForm(
                                  controller: _authBasicController,
                                  usernameFocusNode: _focusManager.authBasicUsernameFocusNode,
                                  passwordFocusNode: _focusManager.authBasicPasswordFocusNode,
                                ),
                                // Bearer Token
                                AuthBearerForm(
                                  controller: _authBearerController,
                                  tokenFocusNode: _focusManager.authBearerTokenFocusNode,
                                ),
                                // Digest
                                AuthNotImplemented(authType: 'Digest auth'),
                                // OAuth2
                                AuthNotImplemented(authType: 'OAuth2'),
                                // WSSE
                                AuthNotImplemented(authType: 'WSSE auth'),
                              ],
                            ),
                            // -----------------------------------------------------------
                            // Variables Tab
                            // -----------------------------------------------------------
                            SingleChildScrollView(
                              child: FormTable(
                                controller: _varsController,
                                columns: [
                                  FormTableColumn.enabled,
                                  FormTableColumn.key,
                                  FormTableColumn.value,
                                  FormTableColumn.delete,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    key: ValueKey("save_btn"),
                    onPressed: _onSave,
                    style: commonButtonStyle,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
