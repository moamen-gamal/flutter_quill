import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Declare Controller , Toolbar , editor and custom buttons
  // and define them in the 'initState' function
  late QuillController _controller;
  late Widget ToolBar;
  late Widget Editor;

  late var saveCustomButton;

  late var openCustomButton;
  //pick files from from the drive
  Future<String?> openFileSystemPickerForDesktop(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return null;
    }
    final fileName = result.files.first.name;
    final file = File(fileName);
    return file.path;
  }

  // defines the behaviour when picking an image
  Future<String> _onImagePickCallback(File file) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');
    return copiedFile.path.toString();
  }

  // function to open file and is related to the open file button
  Future<void> _onOpenFile() async {
    final result = await FilePicker.platform
        .pickFiles(allowedExtensions: ["json"], allowMultiple: false);
    if (result == null) {
      return;
    }
    final fileData = File(result.files.first.path!).readAsStringSync();
    final doc = Document.fromJson(jsonDecode(fileData.toString()));

    setState(() {
      _controller.document = doc;
    });
  }

  //function to save the data as a json file to be opened later
  Future<void> _onSaveFile() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: "Save File",
      allowedExtensions: ["json"],
    );
    if (result == null) {
      return;
    }

    if (await File(result).exists()) {
      var file = File(result);
      file.delete();
    }
    var file = File(result);
    var writer = file.openWrite();
    writer.write(jsonEncode(_controller.document.toDelta().toJson()));
    writer.close();
    return;
  }

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();

    saveCustomButton =
        QuillCustomButton(icon: Icons.save, onTap: () => _onSaveFile());

    openCustomButton =
        QuillCustomButton(icon: Icons.folder, onTap: () => _onOpenFile());

    ToolBar = QuillToolbar.basic(
      controller: _controller,
      embedButtons: FlutterQuillEmbeds.buttons(
        showVideoButton: false,
        onImagePickCallback: _onImagePickCallback,
        filePickImpl: openFileSystemPickerForDesktop,
      ),
      customButtons: [saveCustomButton, openCustomButton],
      showAlignmentButtons: true,
    );

    Editor = QuillEditor.basic(
      controller: _controller,
      embedBuilders: FlutterQuillEmbeds.builders(),
      readOnly: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ToolBar,
            Expanded(child: Editor),
          ],
        ),
      ),
    );
  }
}
