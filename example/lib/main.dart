import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(HtmlEditorExampleApp());

class HtmlEditorExampleApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      home: HtmlEditorExample(title: 'Flutter HTML Editor Example'),
    );
  }
}

class HtmlEditorExample extends StatefulWidget {
  HtmlEditorExample({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HtmlEditorExampleState createState() => _HtmlEditorExampleState();
}

class _HtmlEditorExampleState extends State<HtmlEditorExample> {
  String result = '';
  final HtmlEditorController controller = HtmlEditorController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!kIsWeb) {
          controller.clearFocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 0,
          actions: [
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  if (kIsWeb) {
                    controller.reloadWeb();
                  } else {
                    controller.editorController!.reload();
                  }
                })
          ],
        ),
        body: Editor(textInnit: '', onChange: (String value) {  },),
      ),
    );
  }
}
class Editor extends StatefulWidget {
  const Editor({
    required this.textInnit,
    required this.onChange,
  });

  final String textInnit;
  final Function(String value) onChange;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  HtmlEditorController controller = HtmlEditorController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: HtmlEditor(
            callbacks: Callbacks(
              onInit: () {
                controller.setFocus();
                controller.setFullScreen();
              },
              onChangeContent: (value) => print(value),
              onChangeSelection: (value) {
             
              },
              onFocus: () {
              },
              onPaste: () {},
            ),
            htmlToolbarOptions: HtmlToolbarOptions(
              separatorWidget: Container(
                width: 1,
                height: 24,
                color: Color(0xFFD9D9D9),
              ),
              toolbarItemHeight: 24,
              toolbarType: ToolbarType.nativeScrollable,
              renderBorder: false,
              gridViewHorizontalSpacing: 1,
              gridViewVerticalSpacing: 0,
              dropdownIconSize: 24,
              dropdownItemHeight: 50,
              dropdownMenuDirection: DropdownMenuDirection.down,
              dropdownBoxDecoration: const BoxDecoration(),
              defaultToolbarButtons: [
                const FontSettingButtons(fontSize: true, fontName: true, fontSizeUnit: false),
              ],
              customToolbarInsertionIndices: [0],
              customToolbarButtons: [
                Row(
                  children: [
                    GestureDetector(
                        onTap: () => controller.undo(),
                        child:Icon(Icons.undo)
                    ),
                    const SizedBox(width:16),
                    GestureDetector(
                        onTap: () => controller.redo(),
                        child:Icon(Icons.redo)
                    ),
                  ],
                ),
              ],
            ),
            controller: controller,
            htmlEditorOptions: HtmlEditorOptions(
              initialText: widget.textInnit,
            ),
            otherOptions: OtherOptions(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
              ),
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  150,
            ), iconUndo: SizedBox(), iconRedo: SizedBox(),
          ),
        ),
      ],
    );
  }
}
