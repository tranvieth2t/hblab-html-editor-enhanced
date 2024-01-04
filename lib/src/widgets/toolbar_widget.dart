import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/utils/utils.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Toolbar widget class
class ToolbarWidget extends StatefulWidget {
  /// The [HtmlEditorController] is mainly used to call the [execCommand] method
  final HtmlEditorController controller;
  final HtmlToolbarOptions htmlToolbarOptions;
  final Callbacks? callbacks;
  final bool isBottom;

  const ToolbarWidget({
    Key? key,
    required this.controller,
    required this.htmlToolbarOptions,
    required this.callbacks,
    this.isBottom = true,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ToolbarWidgetState();
  }
}

/// Toolbar widget state
class ToolbarWidgetState extends State<ToolbarWidget> {
  /// List that controls which [ToggleButtons] are selected for
  /// bold/italic/underline/clear styles
  List<bool> _fontSelected = List<bool>.filled(4, false);

  /// List that controls which [ToggleButtons] are selected for
  /// strikthrough/superscript/subscript
  List<bool> _miscFontSelected = List<bool>.filled(3, false);

  /// List that controls which [ToggleButtons] are selected for
  /// fullscreen, codeview, undo, redo, and help. Fullscreen and codeview
  /// are the only buttons that will ever be selected.
  List<bool> _miscSelected = List<bool>.filled(5, false);

  /// List that controls which [ToggleButtons] are selected for
  /// justify left/right/center/full.
  List<bool> _alignSelected = List<bool>.filled(4, false);

  /// Sets the selected item for the font style dropdown
  String _fontSelectedItem = 'p';

  String _fontNameSelectedItem = 'times new roman';

  /// Sets the selected item for the font size dropdown
  double _fontSizeSelectedItem = 3;

  /// Keeps track of the current font size in px
  double _actualFontSizeSelectedItem = 16;

  /// Sets the selected item for the font units dropdown
  String _fontSizeUnitSelectedItem = 'px';

  /// Sets the selected item for the line height dropdown
  double _lineHeightSelectedItem = 1.0;

  /// Masks the toolbar with a grey color if false
  bool _enabled = true;

  /// Tracks the expanded status of the toolbar
  bool _isExpanded = false;

  @override
  void initState() {
    if (!widget.isBottom) {
      widget.controller.toolbar = this;
    } else {
      widget.controller.toolbarBottom = this;
    }
    _isExpanded = widget.htmlToolbarOptions.initiallyExpanded;
    for (var t in widget.htmlToolbarOptions.defaultToolbarButtons) {
      if (t is FontButtons) {
        _fontSelected = List<bool>.filled(t.getIcons1().length, false);
        _miscFontSelected = List<bool>.filled(t.getIcons2().length, false);
      }
      if (t is OtherButtons) {
        _miscSelected = List<bool>.filled(t.getIcons1().length, false);
      }
      if (t is ParagraphButtons) {
        _alignSelected = List<bool>.filled(t.getIcons1().length, false);
      }
    }
    super.initState();
  }

  void disable() {
    setState(mounted, this.setState, () {
      _enabled = false;
    });
  }

  void enable() {
    setState(mounted, this.setState, () {
      _enabled = true;
    });
  }

  /// Updates the toolbar from the JS handler on mobile and the onMessage
  /// listener on web
  void updateToolbar(Map<String, dynamic> json) {
    //get parent element
    //get font name
    var fontName = (json['fontName'] ?? '').toString().replaceAll('"', '');
    //get font size
    var fontSize = double.tryParse(json['fontSize']) ?? 3;
    //get bold/underline/italic status
    var fontList = (json['font'] as List<dynamic>).cast<bool?>();
    //get superscript/subscript/strikethrough status
    var miscFontList = (json['miscFont'] as List<dynamic>).cast<bool?>();
    //get forecolor/backcolor
    //get ordered/unordered list status
    var paragraphList = (json['paragraph'] as List<dynamic>).cast<bool?>();
    //get justify status
    var alignList = (json['align'] as List<dynamic>).cast<bool?>();
    //get line height
    String lineHeight = json['lineHeight'] ?? '';
    //get list icon type
    if (['courier new', 'sans-serif', 'times new roman']
        .contains(fontName.toLowerCase())) {
      setState(mounted, this.setState, () {
        _fontNameSelectedItem = fontName.toLowerCase();
      });
    } else {
      setState(mounted, this.setState, () {
        _fontNameSelectedItem = 'times new roman';
      });
    }
    //update the lineheight selected item if necessary
    if (lineHeight.isNotEmpty && lineHeight.endsWith('px')) {
      var lineHeightDouble =
          double.tryParse(lineHeight.replaceAll('px', '')) ?? 16;
      var lineHeights = <double>[1, 2];
      lineHeights =
          lineHeights.map((e) => e * _actualFontSizeSelectedItem).toList();
      if (lineHeights.contains(lineHeightDouble)) {
        setState(mounted, this.setState, () {
          _lineHeightSelectedItem =
              lineHeightDouble / _actualFontSizeSelectedItem;
        });
      }
    } else if (lineHeight == 'normal') {
      setState(mounted, this.setState, () {
        _lineHeightSelectedItem = 1.0;
      });
    }
    //check if the font size matches one of the predetermined sizes and update the toolbar
    if ([1, 2, 3, 4, 5, 6, 7].contains(fontSize)) {
      setState(mounted, this.setState, () {
        _fontSizeSelectedItem = fontSize;
      });
    }
    //use the remaining bool lists to update the selected items accordingly
    setState(mounted, this.setState, () {
      for (var t in widget.htmlToolbarOptions.defaultToolbarButtons) {
        if (t is FontButtons) {
          for (var i = 0; i < _fontSelected.length; i++) {
            if (t.getIcons1()[i].icon == Icons.format_bold) {
              _fontSelected[i] = fontList[0] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_italic) {
              _fontSelected[i] = fontList[1] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_underline) {
              _fontSelected[i] = fontList[2] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.strikethrough_s) {
              _fontSelected[i] = fontList[3] ?? false;
            }
          }
          for (var i = 0; i < _miscFontSelected.length; i++) {
            if (t.getIcons2()[i].icon == Icons.format_strikethrough) {
              _miscFontSelected[i] = miscFontList[0] ?? false;
            }
            if (t.getIcons2()[i].icon == Icons.superscript) {
              _miscFontSelected[i] = miscFontList[1] ?? false;
            }
            if (t.getIcons2()[i].icon == Icons.subscript) {
              _miscFontSelected[i] = miscFontList[2] ?? false;
            }
          }
        }

        if (t is ParagraphButtons) {
          for (var i = 0; i < _alignSelected.length; i++) {
            if (t.getIcons1()[i].icon == Icons.format_align_left) {
              _alignSelected[i] = alignList[0] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_align_center) {
              _alignSelected[i] = alignList[1] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_align_right) {
              _alignSelected[i] = alignList[2] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_align_justify) {
              _alignSelected[i] = alignList[3] ?? false;
            }
          }
        }
      }
    });
    if (widget.callbacks?.onChangeSelection != null) {
      widget.callbacks!.onChangeSelection!.call(EditorSettings(
          parentElement: 'p',
          fontName: fontName,
          fontSize: fontSize,
          isBold: fontList[0] ?? false,
          isItalic: fontList[1] ?? false,
          isUnderline: fontList[2] ?? false,
          isStrikethrough: miscFontList[0] ?? false,
          isSuperscript: miscFontList[1] ?? false,
          isSubscript: miscFontList[2] ?? false,
          isUl: paragraphList[0] ?? false,
          isOl: paragraphList[1] ?? false,
          isAlignLeft: alignList[0] ?? false,
          isAlignCenter: alignList[1] ?? false,
          isAlignRight: alignList[2] ?? false,
          isAlignJustify: alignList[3] ?? false,
          lineHeight: _lineHeightSelectedItem,
          textDirection: TextDirection.rtl,
          foregroundColor: Colors.black,
          backgroundColor: Colors.white));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.htmlToolbarOptions.toolbarType == ToolbarType.nativeGrid) {
      return PointerInterceptor(
        child: AbsorbPointer(
          absorbing: !_enabled,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Wrap(
                runSpacing: widget.htmlToolbarOptions.gridViewVerticalSpacing,
                spacing: widget.htmlToolbarOptions.gridViewHorizontalSpacing,
                children: _buildChildren(),
              ),
            ),
          ),
        ),
      );
    } else if (widget.htmlToolbarOptions.toolbarType ==
        ToolbarType.nativeScrollable) {
      return PointerInterceptor(
        child: AbsorbPointer(
          absorbing: !_enabled,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: Container(
              height: widget.htmlToolbarOptions.toolbarItemHeight + 15,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: CustomScrollView(
                  scrollDirection: Axis.horizontal,
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildChildren(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else if (widget.htmlToolbarOptions.toolbarType ==
        ToolbarType.nativeExpandable) {
      return PointerInterceptor(
        child: AbsorbPointer(
          absorbing: !_enabled,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: _isExpanded
                    ? MediaQuery.of(context).size.height
                    : widget.htmlToolbarOptions.toolbarItemHeight + 15,
              ),
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Wrap(
                        runSpacing:
                            widget.htmlToolbarOptions.gridViewVerticalSpacing,
                        spacing:
                            widget.htmlToolbarOptions.gridViewHorizontalSpacing,
                        children: _buildChildren()
                          ..insert(
                              0,
                              Container(
                                height:
                                    widget.htmlToolbarOptions.toolbarItemHeight,
                                child: IconButton(
                                  icon: Icon(
                                    _isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () async {
                                    setState(mounted, this.setState, () {
                                      _isExpanded = !_isExpanded;
                                    });
                                    await Future.delayed(
                                        Duration(milliseconds: 100));
                                    if (kIsWeb) {
                                      widget.controller.recalculateHeight();
                                    } else {
                                      await widget.controller.editorController!
                                          .evaluateJavascript(
                                              source:
                                                  "var height = \$('div.note-editable').outerHeight(true); window.flutter_inappwebview.callHandler('setHeight', height);");
                                    }
                                  },
                                ),
                              )),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: ExpandIconDelegate(
                                widget.htmlToolbarOptions.toolbarItemHeight,
                                _isExpanded, () async {
                              setState(mounted, this.setState, () {
                                _isExpanded = !_isExpanded;
                              });
                              await Future.delayed(Duration(milliseconds: 100));
                              if (kIsWeb) {
                                widget.controller.recalculateHeight();
                              } else {
                                await widget.controller.editorController!
                                    .evaluateJavascript(
                                        source:
                                            "var height = \$('div.note-editable').outerHeight(true); window.flutter_inappwebview.callHandler('setHeight', height);");
                              }
                            }),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _buildChildren(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );
    }
    return Container(height: 0, width: 0);
  }

  List<Widget> _buildChildren() {
    var toolbarChildren = <Widget>[];
    for (var t in widget.htmlToolbarOptions.defaultToolbarButtons) {
      if (t is FontSettingButtons) {
        if (t.fontName) {
          toolbarChildren.add(Container(
            padding: const EdgeInsets.only(left: 8.0),
            height: widget.htmlToolbarOptions.toolbarItemHeight,
            decoration: !widget.htmlToolbarOptions.renderBorder
                ? null
                : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                    BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12))),
            child: CustomDropdownButtonHideUnderline(
              child: CustomDropdownButton<String>(
                elevation: widget.htmlToolbarOptions.dropdownElevation,
                icon: widget.htmlToolbarOptions.dropdownIcon,
                iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
                iconSize: widget.htmlToolbarOptions.dropdownIconSize,
                itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
                focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
                dropdownColor:
                    widget.htmlToolbarOptions.dropdownBackgroundColor,
                menuDirection:
                    widget.htmlToolbarOptions.dropdownMenuDirection ??
                        (widget.htmlToolbarOptions.toolbarPosition ==
                                ToolbarPosition.belowEditor
                            ? DropdownMenuDirection.up
                            : DropdownMenuDirection.down),
                menuMaxHeight:
                    widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                        MediaQuery.of(context).size.height / 3,
                style: widget.htmlToolbarOptions.textStyle,
                items: [
                  CustomDropdownMenuItem(
                    value: 'times new roman',
                    child: PointerInterceptor(
                        child: Text('Times New Roman',
                            style: TextStyle(fontFamily: 'Times'))),
                  ),
                  CustomDropdownMenuItem(
                    value: 'courier new',
                    child: PointerInterceptor(
                        child: Text('Courier New',
                            style: TextStyle(fontFamily: 'Courier'))),
                  ),
                  CustomDropdownMenuItem(
                    value: 'sans-serif',
                    child: PointerInterceptor(
                        child: Text('Sans Serif',
                            style: TextStyle(fontFamily: 'sans-serif'))),
                  ),
                ],
                value: _fontNameSelectedItem,
                onChanged: (String? changed) async {
                  void updateSelectedItem(dynamic changed) async {
                    if (changed is String) {
                      setState(mounted, this.setState, () {
                        _fontNameSelectedItem = changed;
                      });
                    }
                  }

                  if (changed != null) {
                    var proceed =
                        await widget.htmlToolbarOptions.onDropdownChanged?.call(
                                DropdownType.fontName,
                                changed,
                                updateSelectedItem) ??
                            true;
                    if (proceed) {
                      widget.controller
                          .execCommand('fontName', argument: changed);
                      updateSelectedItem(changed);
                    }
                  }
                },
              ),
            ),
          ));
        }
        if (t.fontSize) {
          toolbarChildren.add(Container(
            padding: const EdgeInsets.only(left: 8.0),
            height: widget.htmlToolbarOptions.toolbarItemHeight,
            decoration: !widget.htmlToolbarOptions.renderBorder
                ? null
                : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                    BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12))),
            child: CustomDropdownButtonHideUnderline(
              child: CustomDropdownButton<double>(
                elevation: widget.htmlToolbarOptions.dropdownElevation,
                icon: widget.htmlToolbarOptions.dropdownIcon,
                iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
                iconSize: widget.htmlToolbarOptions.dropdownIconSize,
                itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
                focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
                dropdownColor:
                    widget.htmlToolbarOptions.dropdownBackgroundColor,
                menuDirection:
                    widget.htmlToolbarOptions.dropdownMenuDirection ??
                        (widget.htmlToolbarOptions.toolbarPosition ==
                                ToolbarPosition.belowEditor
                            ? DropdownMenuDirection.up
                            : DropdownMenuDirection.down),
                menuMaxHeight:
                    widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                        MediaQuery.of(context).size.height / 3,
                style: widget.htmlToolbarOptions.textStyle,
                items: [
                  CustomDropdownMenuItem(
                    value: 1,
                    child: PointerInterceptor(
                        child: Text(
                            "${_fontSizeUnitSelectedItem == "px" ? "12" : "8"}")),
                  ),
                  CustomDropdownMenuItem(
                    value: 2,
                    child: PointerInterceptor(
                        child: Text(
                            "${_fontSizeUnitSelectedItem == "px" ? "14" : "10"}")),
                  ),
                  CustomDropdownMenuItem(
                    value: 3,
                    child: PointerInterceptor(
                        child: Text(
                            "${_fontSizeUnitSelectedItem == "px" ? "16" : "12"}")),
                  ),
                  CustomDropdownMenuItem(
                    value: 4,
                    child: PointerInterceptor(
                        child: Text(
                            "${_fontSizeUnitSelectedItem == "px" ? "18" : "14"}")),
                  ),
                  CustomDropdownMenuItem(
                    value: 5,
                    child: PointerInterceptor(
                        child: Text(
                            "${_fontSizeUnitSelectedItem == "px" ? "24" : "18"}")),
                  ),
                  CustomDropdownMenuItem(
                    value: 6,
                    child: PointerInterceptor(
                        child: Text(
                            "${_fontSizeUnitSelectedItem == "px" ? "32" : "24"}")),
                  ),
                  CustomDropdownMenuItem(
                    value: 7,
                    child: PointerInterceptor(
                        child: Text(
                            "${_fontSizeUnitSelectedItem == "px" ? "48" : "36"}")),
                  ),
                ],
                value: _fontSizeSelectedItem,
                onChanged: (double? changed) async {
                  void updateSelectedItem(dynamic changed) {
                    if (changed is double) {
                      setState(mounted, this.setState, () {
                        _fontSizeSelectedItem = changed;
                      });
                    }
                  }

                  if (changed != null) {
                    var intChanged = changed.toInt();
                    var proceed =
                        await widget.htmlToolbarOptions.onDropdownChanged?.call(
                                DropdownType.fontSize,
                                changed,
                                updateSelectedItem) ??
                            true;
                    if (proceed) {
                      switch (intChanged) {
                        case 1:
                          _actualFontSizeSelectedItem = 12;
                          break;
                        case 2:
                          _actualFontSizeSelectedItem = 14;
                          break;
                        case 3:
                          _actualFontSizeSelectedItem = 16;
                          break;
                        case 4:
                          _actualFontSizeSelectedItem = 18;
                          break;
                        case 5:
                          _actualFontSizeSelectedItem = 24;
                          break;
                        case 6:
                          _actualFontSizeSelectedItem = 32;
                          break;
                        case 7:
                          _actualFontSizeSelectedItem = 48;
                          break;
                        default:
                          _actualFontSizeSelectedItem = 16;
                      }
                      widget.controller.execCommand('fontSize',
                          argument: changed.toString());
                      updateSelectedItem(changed);
                    }
                  }
                },
              ),
            ),
          ));
        }
        if (t.fontSizeUnit) {
          toolbarChildren.add(Container(
            padding: const EdgeInsets.only(left: 8.0),
            height: widget.htmlToolbarOptions.toolbarItemHeight,
            decoration: !widget.htmlToolbarOptions.renderBorder
                ? null
                : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                    BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12))),
            child: CustomDropdownButtonHideUnderline(
              child: CustomDropdownButton<String>(
                elevation: widget.htmlToolbarOptions.dropdownElevation,
                icon: widget.htmlToolbarOptions.dropdownIcon,
                iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
                iconSize: widget.htmlToolbarOptions.dropdownIconSize,
                itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
                focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
                dropdownColor:
                    widget.htmlToolbarOptions.dropdownBackgroundColor,
                menuDirection:
                    widget.htmlToolbarOptions.dropdownMenuDirection ??
                        (widget.htmlToolbarOptions.toolbarPosition ==
                                ToolbarPosition.belowEditor
                            ? DropdownMenuDirection.up
                            : DropdownMenuDirection.down),
                menuMaxHeight:
                    widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                        MediaQuery.of(context).size.height / 3,
                style: widget.htmlToolbarOptions.textStyle,
                items: [
                  CustomDropdownMenuItem(
                    value: 'pt',
                    child: PointerInterceptor(child: Text('pt')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'px',
                    child: PointerInterceptor(child: Text('px')),
                  ),
                ],
                value: _fontSizeUnitSelectedItem,
                onChanged: (String? changed) async {
                  void updateSelectedItem(dynamic changed) {
                    if (changed is String) {
                      setState(mounted, this.setState, () {
                        _fontSizeUnitSelectedItem = changed;
                      });
                    }
                  }

                  if (changed != null) {
                    var proceed =
                        await widget.htmlToolbarOptions.onDropdownChanged?.call(
                                DropdownType.fontSizeUnit,
                                changed,
                                updateSelectedItem) ??
                            true;
                    if (proceed) {
                      updateSelectedItem(changed);
                    }
                  }
                },
              ),
            ),
          ));
        }
      }
      if (t is FontButtons) {
        if (t.bold || t.italic || t.underline || t.strikeThrough2) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                setState(mounted, this.setState, () {
                  _fontSelected[index] = !_fontSelected[index];
                });
              }

              if (t.getIcons1()[index].icon == Icons.format_bold) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.bold, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('bold');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_italic) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.italic, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('italic');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_underline) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.underline, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('underline');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.strikethrough_s) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.strikethrough, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('strikeThrough');
                  updateStatus();
                }
              }
            },
            isSelected: _fontSelected,
            children: t.getIcons1(),
          ));
        }
        if (t.strikethrough || t.superscript || t.subscript) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                setState(mounted, this.setState, () {
                  _miscFontSelected[index] = !_miscFontSelected[index];
                });
              }

              if (t.getIcons2()[index].icon == Icons.format_strikethrough) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.strikethrough,
                            _miscFontSelected[index], updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('strikeThrough');
                  updateStatus();
                }
              }
              if (t.getIcons2()[index].icon == Icons.superscript) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.superscript, _miscFontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('superscript');
                  updateStatus();
                }
              }
              if (t.getIcons2()[index].icon == Icons.subscript) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.subscript, _miscFontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('subscript');
                  updateStatus();
                }
              }
            },
            isSelected: _miscFontSelected,
            children: t.getIcons2(),
          ));
        }
      }
      if (t is ParagraphButtons) {
        if (t.alignLeft || t.alignCenter || t.alignRight || t.alignJustify) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                _alignSelected = List<bool>.filled(t.getIcons1().length, false);
                setState(mounted, this.setState, () {
                  _alignSelected[index] = !_alignSelected[index];
                });
              }

              if (t.getIcons1()[index].icon == Icons.format_align_left) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignLeft, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyLeft');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_align_center) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignCenter, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyCenter');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_align_right) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignRight, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyRight');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_align_justify) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignJustify, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyFull');
                  updateStatus();
                }
              }
            },
            isSelected: _alignSelected,
            children: t.getIcons1(),
          ));
        }
        if (t.lineHeight) {
          toolbarChildren.add(CustomDropdownButtonHideUnderline(
            child: CustomDropdownButton<double>(
              isHideValue: true,
              elevation: widget.htmlToolbarOptions.dropdownElevation,
              icon: Icon(Icons.format_line_spacing),
              iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
              iconSize: widget.htmlToolbarOptions.dropdownIconSize,
              itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
              focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
              dropdownColor: widget.htmlToolbarOptions.dropdownBackgroundColor,
              menuDirection: widget.htmlToolbarOptions.dropdownMenuDirection ??
                  (widget.htmlToolbarOptions.toolbarPosition ==
                          ToolbarPosition.belowEditor
                      ? DropdownMenuDirection.up
                      : DropdownMenuDirection.down),
              menuMaxHeight: widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                  MediaQuery.of(context).size.height / 3,
              style: widget.htmlToolbarOptions.textStyle,
              items: [
                CustomDropdownMenuItem(
                    value: 1,
                    child: PointerInterceptor(
                        child: Text(
                      'Single',
                      style: TextStyle(fontSize: 14),
                    ))),
                CustomDropdownMenuItem(
                    value: 2, child: PointerInterceptor(child: Text('2'))),
              ],
              value: _lineHeightSelectedItem,
              onChanged: (double? changed) async {
                void updateSelectedItem(dynamic changed) {
                  if (changed is double) {
                    setState(mounted, this.setState, () {
                      _lineHeightSelectedItem = changed;
                    });
                  }
                }

                if (changed != null) {
                  var proceed =
                      await widget.htmlToolbarOptions.onDropdownChanged?.call(
                              DropdownType.lineHeight,
                              changed,
                              updateSelectedItem) ??
                          true;
                  if (proceed) {
                    if (kIsWeb) {
                      widget.controller.changeLineHeight(changed.toString());
                    } else {
                      await widget.controller.editorController!.evaluateJavascript(
                          source:
                              "\$('#summernote-2').summernote('lineHeight', '$changed');");
                    }
                    updateSelectedItem(changed);
                  }
                }
              },
            ),
          ));
        }

        if (t.increaseIndent || t.decreaseIndent) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              if (t.getIcons2()[index].icon == Icons.format_indent_increase) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.increaseIndent, null, null) ??
                    true;
                if (proceed) {
                  widget.controller.indent();
                }
              }
              if (t.getIcons2()[index].icon == Icons.format_indent_decrease) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.decreaseIndent, null, null) ??
                    true;
                if (proceed) {
                  widget.controller.outdent();
                }
              }
            },
            isSelected: List<bool>.filled(t.getIcons2().length, false),
            children: t.getIcons2(),
          ));
        }
      }
    }
    if (widget.htmlToolbarOptions.customToolbarInsertionIndices.isNotEmpty &&
        widget.htmlToolbarOptions.customToolbarInsertionIndices.length ==
            widget.htmlToolbarOptions.customToolbarButtons.length) {
      for (var i = 0;
          i < widget.htmlToolbarOptions.customToolbarInsertionIndices.length;
          i++) {
        if (widget.htmlToolbarOptions.customToolbarInsertionIndices[i] >
            toolbarChildren.length) {
          toolbarChildren.insert(toolbarChildren.length,
              widget.htmlToolbarOptions.customToolbarButtons[i]);
        } else if (widget.htmlToolbarOptions.customToolbarInsertionIndices[i] <
            0) {
          toolbarChildren.insert(
              0, widget.htmlToolbarOptions.customToolbarButtons[i]);
        } else {
          toolbarChildren.insert(
              widget.htmlToolbarOptions.customToolbarInsertionIndices[i],
              widget.htmlToolbarOptions.customToolbarButtons[i]);
        }
      }
    } else {
      toolbarChildren.addAll(widget.htmlToolbarOptions.customToolbarButtons);
    }
    if (widget.htmlToolbarOptions.renderSeparatorWidget) {
      toolbarChildren = intersperse(
              widget.htmlToolbarOptions.separatorWidget, toolbarChildren)
          .toList();
    }
    return toolbarChildren;
  }
}
