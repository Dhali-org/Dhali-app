import 'dart:async';
import 'dart:convert';

import 'dart:math';
import "package:universal_html/html.dart" as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/utils/show_popup_text_with_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

import 'package:dhali/analytics/analytics.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/config.dart' show Config;
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali/utils/Uploaders.dart';
import 'package:dhali/utils/not_implemented_dialog.dart';
import 'package:dhali/utils/display_utils.dart';
import 'package:dhali/utils/row_else_column.dart';

class DataEndpointPair {
  DataEndpointPair({required this.data, required this.endPoint});

  AssetModel data;
  String endPoint;
}

class DropzoneRunWidget extends StatefulWidget {
  final ValueChanged<AssetModel> onDroppedFile;
  final Function(AssetModel) onNextClicked;

  const DropzoneRunWidget({
    super.key,
    required this.onDroppedFile,
    required this.onNextClicked,
  });
  @override
  _DropzoneRunWidgetState createState() => _DropzoneRunWidgetState();
}

class _DropzoneRunWidgetState extends State<DropzoneRunWidget> {
  DropzoneViewController? controller;
  bool isHighlighted = false;
  AssetModel? input;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      child: Stack(
        children: [
          Container(
            decoration: isHighlighted
                ? const BoxDecoration(
                    gradient: RadialGradient(colors: [
                      AppTheme.grey,
                      Colors.transparent,
                    ]),
                    shape: BoxShape.circle,
                  )
                : const BoxDecoration(color: Colors.transparent),
          ),
          DropzoneView(
            onHover: () => setState(() {
              isHighlighted = true;
            }),
            onLeave: () => setState(() {
              isHighlighted = false;
            }),
            onCreated: (controller) => this.controller = controller,
            onDrop: acceptFile,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      input != null
                          ? "Selected input file: ${input!.fileName}"
                          : "No input file selected",
                      style: TextStyle(
                          fontSize: isDesktopResolution(context) ? 20 : 10),
                    ),
                    SizedBox(
                      width: isDesktopResolution(context) ? 16 : 5,
                      height: isDesktopResolution(context) ? 16 : 5,
                    ),
                    if (input == null)
                      IconButton(
                        onPressed: () async {
                          showNotImplentedWidget(
                              context: context,
                              feature: "Helper: Selected input file");
                          // TODO : Add link to documentation for docker prep
                        },
                        icon: Icon(
                          Icons.help_outline_outlined,
                          size: isDesktopResolution(context) ? 32 : 16,
                        ),
                      )
                    else
                      Icon(
                        Icons.done_outline_rounded,
                        color: Colors.green,
                        size: isDesktopResolution(context) ? 80 : 40,
                      ),
                  ],
                ),
                Icon(
                  Icons.cloud_upload_rounded,
                  size: isDesktopResolution(context) ? 80 : 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      "Drag or select your input file",
                      style: TextStyle(
                          fontSize: isDesktopResolution(context) ? 30 : 10,
                          color: isHighlighted
                              ? Theme.of(context).colorScheme.onBackground
                              : Theme.of(context).colorScheme.onSecondary),
                    ),
                    SizedBox(
                      height: isDesktopResolution(context) ? 16 : 2,
                      width: isDesktopResolution(context) ? 16 : 2,
                    ),
                    IconButton(
                      onPressed: () async {
                        showNotImplentedWidget(
                            context: context,
                            feature: "Helper: Drag or select your input file");
                        // TODO : Add link to documentation for docker prep
                      },
                      icon: Icon(
                        Icons.help_outline_outlined,
                        size: isDesktopResolution(context) ? 32 : 16,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: isDesktopResolution(context) ? 16 : 16,
                  width: isDesktopResolution(context) ? 32 : 16,
                ),
                RowElseColumn(
                  isRow: isDesktopResolution(context),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getFileUploadButton(const Key("choose_run_input"),
                        "Choose input file", [], AppTheme.secondary),
                    SizedBox(
                      width: isDesktopResolution(context) ? 16 : 8,
                      height: isDesktopResolution(context) ? 16 : 8,
                    ),
                    ElevatedButton.icon(
                        key: const Key("use_docker_image_button"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        onPressed: input != null
                            ? () async {
                                gtag(
                                    command: "event",
                                    target: "NextClicked",
                                    parameters: {"from": "DropZoneWidget"});
                                widget.onNextClicked(input!);
                              }
                            : null,
                        icon: Icon(
                          color: Theme.of(context).colorScheme.onPrimary,
                          Icons.navigate_next_outlined,
                          size: isDesktopResolution(context) ? 32 : 16,
                        ),
                        label: Text(
                          key: const Key("DropZoneRunNext"),
                          "Next",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: isDesktopResolution(context) ? 30 : 16),
                        )),
                  ],
                )
              ],
            ),
          )
        ],
      ),
      context: context,
    );
  }

  Widget getFileUploadButton(
      Key key, String text, List<String> mime, Color color) {
    return ElevatedButton.icon(
        key: key,
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        onPressed: () async {
          gtag(command: "event", target: "FileUploadClicked");

          // When we run a unit test, `controller` is not
          // correctly initialised. I don't know exactly why.
          // It looks as though it should get init'd through
          // the callback passed to `buildView`,
          // (here)[https://github.com/deakjahn/flutter_dropzone/blob/master/flutter_dropzone/lib/src/dropzone_view.dart#L72]
          // The callback is passed right through to
          // `HtmlElementView` (here)[https://github.com/deakjahn/flutter_dropzone/blob/master/flutter_dropzone_web/lib/flutter_dropzone_plugin.dart#L117]
          // which suggests that the platform view does not get created during the test.
          if (controller != null &&
              const String.fromEnvironment('INTEGRATION') != "true") {
            final events = await controller!.pickFiles(mime: mime);
            if (events.isEmpty) return;
            acceptFile(events.first);
          } else {
            // TODO : This should be injectable
            if (mime.isNotEmpty) {
              acceptFile(html.File(
                  [1, 2, 3, 4, 5, 6, 7], "test.tar", {"type": mime[0]}));
            } else {
              acceptFile(html.File(
                [1, 2, 3, 4, 5, 6, 7],
                "test.tar",
              ));
            }
          }
        },
        icon: Icon(
          Icons.search,
          size: isDesktopResolution(context) ? 32 : 16,
        ),
        label: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isDesktopResolution(context) ? 30 : 12),
        ));
  }

  Future acceptFile(dynamic event) async {
    final fileName = event.name;

    String mime = event.type;
    int bytes = event.size;
    input = AssetModel(
        imageFile: event,
        fileName: fileName,
        modelName: textController.text,
        mime: mime,
        size: bytes);
    setState(() {
      isHighlighted = false;
    });
  }
}

class AssetNameWidget extends StatefulWidget {
  final ValueChanged<AssetModel> onDroppedFile;
  final Function(String, HostingChoice) onNextClicked;
  final int step;
  final int steps;

  const AssetNameWidget(
      {super.key,
      required this.onDroppedFile,
      required this.onNextClicked,
      required this.step,
      required this.steps});
  @override
  _AssetNameWidgetState createState() => _AssetNameWidgetState();
}

class _AssetNameWidgetState extends State<AssetNameWidget> {
  final textController = TextEditingController();

  HostingChoice _choice = HostingChoice.selfHosted;

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      step: widget.step,
      steps: widget.steps,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "What will your API be called?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.start,
            ),
            SizedBox(
                width: 450,
                child: TextField(
                  key: const Key('asset_name_input_field'),
                  onChanged: (value) => {
                    setState(
                      () {},
                    )
                  },
                  controller: textController,
                  maxLength: 64,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 18),
                    helperStyle: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                    labelText: "API name",
                    hintText: "Enter the name you'd like for your asset "
                        "(a-z, 0-9, -, .)",
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("([a-z0-9-]+)"))
                  ],
                )),
            const SizedBox(
              height: 25,
            ),
            HostingRadio(
              onChoiceSelected: (choice) {
                _choice = choice;
              },
              initialChoice: _choice,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                    onPressed: () async {
                      gtag(
                          command: "event",
                          target: "BackClicked",
                          parameters: {"from": "AssetNameWidget"});
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      size: isDesktopResolution(context) ? 25 : 12,
                    ),
                    label: Text(
                      key: const Key("AssetNameBack"),
                      "Back",
                      style: TextStyle(
                          fontSize: isDesktopResolution(context) ? 25 : 12),
                    )),
                const SizedBox(
                  width: 16,
                ),
                ElevatedButton.icon(
                    key: const Key("use_docker_image_button"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                    onPressed: textController.text != ""
                        ? () async {
                            gtag(
                                command: "event",
                                target: "NextClicked",
                                parameters: {"from": "DropZoneDeployWidget"});
                            widget.onNextClicked(textController.text, _choice);
                          }
                        : null,
                    icon: Icon(
                      color: Theme.of(context).colorScheme.onPrimary,
                      Icons.navigate_next_outlined,
                      size: isDesktopResolution(context) ? 25 : 12,
                    ),
                    label: Text(
                      key: const Key("AssetNameNext"),
                      "Next",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: isDesktopResolution(context) ? 25 : 12),
                    )),
              ],
            )
          ],
        ),
      ),
      context: context,
    );
  }
}

class ChargingModelRadio extends StatefulWidget {
  final Function(ChargingChoice) onChoiceSelected;
  final ChargingChoice initialChoice;

  const ChargingModelRadio(
      {super.key, required this.onChoiceSelected, required this.initialChoice});
  @override
  _ChargingModelRadioState createState() => _ChargingModelRadioState();
}

class _ChargingModelRadioState extends State<ChargingModelRadio> {
  ChargingChoice? _choice;

  @override
  void initState() {
    _choice = widget.initialChoice;
    super.initState();
  }

  setChoice(ChargingChoice? choice) {
    setState(() {
      _choice = choice;
      if (_choice != null) {
        widget.onChoiceSelected(_choice!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RadioListTile<ChargingChoice>(
          key: const Key('Per second'),
          title: const Text('Per second'),
          value: ChargingChoice.perSecond,
          groupValue: _choice,
          onChanged: (ChargingChoice? value) {
            setChoice(value);
          },
        ),
        RadioListTile<ChargingChoice>(
          key: const Key('Per request'),
          title: const Text('Per request'),
          value: ChargingChoice.perRequest,
          groupValue: _choice,
          onChanged: (ChargingChoice? value) {
            setChoice(value);
          },
        ),
      ],
    );
  }
}

class HostingRadio extends StatefulWidget {
  final Function(HostingChoice) onChoiceSelected;
  final HostingChoice initialChoice;

  const HostingRadio(
      {super.key, required this.onChoiceSelected, required this.initialChoice});
  @override
  _HostingRadioState createState() => _HostingRadioState();
}

class _HostingRadioState extends State<HostingRadio> {
  HostingChoice? _choice;

  @override
  void initState() {
    _choice = widget.initialChoice;
    super.initState();
  }

  setChoice(HostingChoice? choice) {
    setState(() {
      _choice = choice;
      if (_choice != null) {
        widget.onChoiceSelected(_choice!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("You will need:",
                          style: TextStyle(
                              fontSize: isDesktopResolution(context) ? 18 : 14),
                          textAlign: TextAlign.start),
                      Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                bulletPointItem(
                                    context, 'To know what you\'ll charge'),
                                bulletPointItem(context, 'API base URL'),
                                bulletPointItem(context, 'API key'),
                                bulletPointItem(context,
                                    'A README or an OpenAPI json specification'),
                              ],
                            )
                    ],
                  )),
            ]),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}

Widget bulletPointItem(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '• ',
          style: TextStyle(
              fontSize: isDesktopResolution(context) ? 18 : 12,
              fontWeight: FontWeight.bold),
        ),
        Text(
          text,
          style: TextStyle(fontSize: isDesktopResolution(context) ? 18 : 12),
        ),
      ],
    ),
  );
}

enum HostingChoice { selfHosted, hostedByDhali }

enum ChargingChoice { perRequest, perSecond }

enum DeploymentFile { image, readme }

class DropzoneDeployWidget extends StatefulWidget {
  final ValueChanged<AssetModel> onDroppedFile;
  final Function(AssetModel) onNextClicked;
  final int step;
  final int steps;
  final DeploymentFile deploymentFile;

  const DropzoneDeployWidget(
      {super.key,
      required this.onDroppedFile,
      required this.onNextClicked,
      required this.step,
      required this.steps,
      required this.deploymentFile});
  @override
  _DropzoneDeployWidgetState createState() => _DropzoneDeployWidgetState();
}

class _DropzoneDeployWidgetState extends State<DropzoneDeployWidget> {
  DropzoneViewController? controller;
  bool isHighlighted = false;
  AssetModel? file;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      step: widget.step,
      steps: widget.steps,
      child: Stack(
        children: [
          Container(
            decoration: isHighlighted
                ? const BoxDecoration(
                    gradient: RadialGradient(colors: [
                      AppTheme.grey,
                      Colors.transparent,
                    ]),
                    shape: BoxShape.circle,
                  )
                : const BoxDecoration(color: Colors.transparent),
          ),
          DropzoneView(
            onHover: () => setState(() {
              isHighlighted = true;
            }),
            onLeave: () => setState(() {
              isHighlighted = false;
            }),
            onCreated: (controller) => this.controller = controller,
            onDrop: acceptFile,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.deploymentFile == DeploymentFile.image
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            textAlign: TextAlign.center,
                            file != null
                                ? "Selected asset file: ${file!.fileName}"
                                : "No .tar docker image asset selected",
                            style: TextStyle(
                                fontSize:
                                    isDesktopResolution(context) ? 25 : 12,
                                color: isHighlighted
                                    ? AppTheme.nearlyWhite
                                    : AppTheme.nearlyBlack),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          IconButton(
                            onPressed: () async {
                              gtag(
                                  command: "event",
                                  target: "HelperButtonClicked",
                                  parameters: {"forAction": "Asset upload"});
                              showPopupTextWithLink(
                                  text:
                                      "Please provide a docker image file in '.tar' format.  For instructions, see ",
                                  urlText: "here.",
                                  url:
                                      "https://dhali.io/docs/#/?id=creating-dhali-assets",
                                  context: context);
                            },
                            icon: const Icon(
                              Icons.help_outline_outlined,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          file != null
                              ? const Icon(
                                  Icons.done_outline_rounded,
                                  color: Colors.green,
                                  size: 30,
                                )
                              : Container()
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            textAlign: TextAlign.center,
                            file != null
                                ? "Selected README/OpenAPI json: ${file!.fileName}"
                                : "No README/OpenAPI json selected",
                            style: TextStyle(
                                fontSize:
                                    isDesktopResolution(context) ? 25 : 12),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          IconButton(
                            onPressed: () async {
                              gtag(
                                  command: "event",
                                  target: "HelperButtonClicked",
                                  parameters: {
                                    "forAction": "README.md upload"
                                  });
                              showPopupTextWithLink(
                                  text:
                                      "Please provide a 'README.md' or OpenAPI json file documenting your api.  For more information, see ",
                                  urlText: "here.",
                                  url:
                                      "https://dhali.io/docs/#/?id=creating-dhali-assets",
                                  context: context);
                            },
                            icon: const Icon(
                              Icons.help_outline_outlined,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          file != null
                              ? const Icon(
                                  Icons.done_outline_rounded,
                                  color: Colors.green,
                                  size: 30,
                                )
                              : Container()
                        ],
                      ),
                const Icon(
                  Icons.cloud_upload_rounded,
                  size: 80,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      "Drag or select your file",
                      style: TextStyle(
                          fontSize: isDesktopResolution(context) ? 25 : 12),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                const SizedBox(
                  width: 16,
                ),
                RowElseColumn(
                  isRow: isDesktopResolution(context),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        onPressed: () async {
                          gtag(
                              command: "event",
                              target: "BackClicked",
                              parameters: {"from": "DropZoneDeployWidget"});
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          size: isDesktopResolution(context) ? 25 : 12,
                        ),
                        label: Text(
                          key: const Key("DropZoneDeployBack"),
                          "Back",
                          style: TextStyle(
                              fontSize: isDesktopResolution(context) ? 25 : 12),
                        )),
                    const SizedBox(
                      width: 16,
                    ),
                    widget.deploymentFile == DeploymentFile.image
                        ? getFileUploadButton(
                            const Key("choose_docker_image_button"),
                            "Select",
                            ["application/x-tar"],
                            AppTheme.secondary)
                        : getFileUploadButton(
                            const Key("choose_readme_button"),
                            "Select",
                            [
                              "text/markdown",
                              "text/x-markdown"
                            ], // TODO : This is not filtering the correct mime type
                            AppTheme.secondary),
                    const SizedBox(
                      width: 16,
                    ),
                    ElevatedButton.icon(
                        key: const Key("use_docker_image_button"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        onPressed: file != null
                            ? () async {
                                gtag(
                                    command: "event",
                                    target: "NextClicked",
                                    parameters: {
                                      "from": "DropZoneDeployWidget"
                                    });
                                widget.onNextClicked(file!);
                              }
                            : null,
                        icon: Icon(
                          color: Theme.of(context).colorScheme.onPrimary,
                          Icons.navigate_next_outlined,
                          size: isDesktopResolution(context) ? 25 : 12,
                        ),
                        label: Text(
                          key: widget.deploymentFile == DeploymentFile.image
                              ? const Key("DockerDropZoneDeployNext")
                              : const Key("ReadmeDropZoneDeployNext"),
                          "Next",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: isDesktopResolution(context) ? 25 : 12),
                        )),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
      context: context,
    );
  }

  Widget getFileUploadButton(
      Key key, String text, List<String> mime, Color color) {
    return ElevatedButton.icon(
        key: key,
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        onPressed: () async {
          gtag(command: "event", target: "FileUploadClicked");

          // When we run a unit test, `controller` is not
          // correctly initialised. I don't know exactly why.
          // It looks as though it should get init'd through
          // the callback passed to `buildView`,
          // (here)[https://github.com/deakjahn/flutter_dropzone/blob/master/flutter_dropzone/lib/src/dropzone_view.dart#L72]
          // The callback is passed right through to
          // `HtmlElementView` (here)[https://github.com/deakjahn/flutter_dropzone/blob/master/flutter_dropzone_web/lib/flutter_dropzone_plugin.dart#L117]
          // which suggests that the platform view does not get created during the test.
          if (controller != null &&
              const String.fromEnvironment('INTEGRATION') != "true") {
            final events = await controller!.pickFiles(mime: mime);
            if (events.isEmpty) return;
            if (events.first.size > 0) {
              acceptFile(events.first);
            } else {
              await showDialog(
                  context: context,
                  builder: (BuildContext _) {
                    return const AlertDialog(
                      title: Text("File invalid"),
                      content: Text("Your selected file must not be empty"),
                    );
                  });
            }
          } else {
            // TODO : This should be injectable
            acceptFile(html.File(
                [1, 2, 3, 4, 5, 6, 7], "test.tar", {"type": mime[0]}));
          }
        },
        icon: Icon(
          Icons.search,
          size: isDesktopResolution(context) ? 25 : 12,
        ),
        label: Text(
          text,
          style: TextStyle(fontSize: isDesktopResolution(context) ? 25 : 12),
        ));
  }

  Future acceptFile(dynamic event) async {
    final fileName = event.name;

    String mime = event.type;
    int bytes = event.size;
    file = AssetModel(
        imageFile: event,
        fileName: fileName,
        modelName: textController.text,
        mime: mime,
        size: bytes);
    widget.onDroppedFile(file!);
    setState(() {
      isHighlighted = false;
    });
  }
}

class ImageScanningWidget extends StatefulWidget {
  final AssetModel file;
  final ValueChanged<AssetModel> onNextClicked;
  final int step;
  final int steps;

  const ImageScanningWidget(
      {super.key,
      required this.file,
      required this.onNextClicked,
      required this.step,
      required this.steps});
  @override
  _ImageScanningWidgetState createState() => _ImageScanningWidgetState();
}

class _ImageScanningWidgetState extends State<ImageScanningWidget> {
  bool scanning = true;
  bool scanSuccess = false;
  String failureReason = "";

  @override
  Widget build(BuildContext context) {
    if (!scanSuccess) scanImage(widget.file);
    return getDialogTemplate(
      step: widget.step,
      steps: widget.steps,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 16,
          ),
          scanning
              ? const SpinKitCubeGrid(
                  size: 80,
                  color: AppTheme.nearlyBlack,
                )
              : scanSuccess
                  ? const Icon(
                      Icons.done_outline_rounded,
                      color: Colors.green,
                      size: 80,
                    )
                  : const Icon(
                      Icons.close_outlined,
                      color: Colors.red,
                      size: 80,
                    ),
          const SizedBox(
            height: 16,
          ),
          scanning
              ? Text(
                  textAlign: TextAlign.center,
                  "Scanning '${widget.file.fileName}'. \nThis may take a "
                  "minute or two. Please wait.",
                  style: TextStyle(
                      fontSize: isDesktopResolution(context) ? 25 : 12),
                )
              : scanSuccess
                  ? Text(
                      "Your image was successfully scanned.",
                      style: TextStyle(
                          fontSize: isDesktopResolution(context) ? 25 : 12),
                    )
                  : Text(
                      textAlign: TextAlign.center,
                      "Image invalid: "
                      "\nFollow the guide for preparing your "
                      "image <here>.",
                      style: TextStyle(
                          fontSize: isDesktopResolution(context) ? 25 : 12),
                    ),
          const SizedBox(
            height: 16,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    backgroundColor: AppTheme.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4))),
                onPressed: () async {
                  gtag(
                      command: "event",
                      target: "BackClicked",
                      parameters: {"from": "DeploymentCostWidget"});
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.arrow_back,
                  size: isDesktopResolution(context) ? 25 : 12,
                ),
                label: Text(
                  key: const Key("ImageScanningBack"),
                  "Back",
                  style: TextStyle(
                      fontSize: isDesktopResolution(context) ? 25 : 12),
                )),
            const SizedBox(
              width: 16,
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4))),
              onPressed: scanSuccess
                  ? () {
                      gtag(
                          command: "event",
                          target: "NextClicked",
                          parameters: {"from": "ImageScanWidget"});
                      widget.onNextClicked(widget.file);
                    }
                  : null,
              icon: Icon(
                color: Theme.of(context).colorScheme.onPrimary,
                Icons.navigate_next_outlined,
                size: isDesktopResolution(context) ? 25 : 12,
              ),
              label: Text(
                key: const Key("ImageScanningNext"),
                "Next",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: isDesktopResolution(context) ? 25 : 12),
              ),
            )
          ]),
        ],
      ),
      context: context,
    );
  }

  Future scanImage(AssetModel file) async {
    // TODO : Add some form of client side scannng (consider adding a signature)
    Timer(const Duration(seconds: 1), () {
      setState(() {
        scanning = false;

        String correctFileType = "application/x-tar";
        double correctFileSize = 7.5e9;

        final isCorrectFileType = widget.file.mime == correctFileType;
        final isCorrectFileSize = widget.file.size < correctFileSize;

        if (widget.file.mime == "application/x-tar" &&
            widget.file.size < correctFileSize) {
          scanSuccess = true;
        } else {
          scanSuccess = false;
          failureReason =
              "\nFile type == $correctFileType: $isCorrectFileType;\n"
              "File size == $correctFileSize: $isCorrectFileSize\n";
        }
      });
    });
  }
}

class ChargeWidget extends StatefulWidget {
  final Function(double, ChargingChoice) onNextClicked;
  final double defaultChargingRate;
  final ChargingChoice defaultChargingChoice;
  final int step;
  final int steps;

  const ChargeWidget(
      {super.key,
      required this.onNextClicked,
      required this.defaultChargingRate,
      required this.defaultChargingChoice,
      required this.step,
      required this.steps});
  @override
  _ChargeWidgetState createState() => _ChargeWidgetState();
}

class _ChargeWidgetState extends State<ChargeWidget> {
  final controller = TextEditingController();
  bool scanning = true;
  late ChargingChoice chargingChoice;

  @override
  void initState() {
    chargingChoice = widget.defaultChargingChoice;
    controller.text = widget.defaultChargingRate.toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      step: widget.step,
      steps: widget.steps,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "How much would you like to earn?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
          const Text(
            textAlign: TextAlign.center,
            "\nKeep this small to encourage usage.\n",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
              width: 250,
              child: Row(
                children: [
                  const Text(
                    "   XRP  ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      key: const Key("percentage_earnings_input"),
                      onChanged: (value) => setState(() {}),
                      controller: controller,
                      // ignore: prefer_const_constructors
                      decoration: InputDecoration(
                        labelStyle: const TextStyle(fontSize: 20),
                        helperStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$')),
                        LengthLimitingTextInputFormatter(10)
                      ], // Only numbers can be entered
                    ),
                  ),
                ],
              )),
          SizedBox(
              width: 250,
              child: ChargingModelRadio(
                  onChoiceSelected: (choice) {
                    setState(() {
                      chargingChoice = choice;
                    });
                  },
                  initialChoice: widget.defaultChargingChoice)),
          const SizedBox(
            height: 16,
          ),
          Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Your API earns you ${controller.text} XRP per ${chargingChoice == ChargingChoice.perRequest ? "request" : "second"}",
                    style: TextStyle(
                        fontSize: isDesktopResolution(context) ? 18 : 12),
                    softWrap: true,
                    textAlign: TextAlign.start,
                  ),
                ),
              ]),
          const SizedBox(
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () async {
                    gtag(
                        command: "event",
                        target: "BackClicked",
                        parameters: {"from": "DeploymentCostWidget"});
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: isDesktopResolution(context) ? 25 : 12,
                  ),
                  label: Text(
                    key: const Key("ImageCostBack"),
                    "Back",
                    style: TextStyle(
                      fontSize: isDesktopResolution(context) ? 25 : 12,
                    ),
                  )),
              const SizedBox(
                width: 16,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4))),
                onPressed: controller.text.isNotEmpty
                    ? () {
                        gtag(
                            command: "event",
                            target: "NextClicked",
                            parameters: {"from": "ImageCostWidget"});
                        widget.onNextClicked(double.tryParse(controller.text)!,
                            chargingChoice); // != null because input "digitsOnly"
                      }
                    : null,
                icon: Icon(
                  color: Theme.of(context).colorScheme.onPrimary,
                  Icons.navigate_next_outlined,
                  size: isDesktopResolution(context) ? 25 : 12,
                ),
                label: Text(
                  key: const Key("ImageCostNext"),
                  "Next",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: isDesktopResolution(context) ? 25 : 12,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
      context: context,
    );
  }
}

class KeyValuePairsPage extends StatefulWidget {
  const KeyValuePairsPage(
      {super.key,
      required this.width,
      required this.getKeyControllers,
      required this.setKeyControllers,
      required this.getValueControllers,
      required this.setValueControllers});

  final List<TextEditingController> Function() getKeyControllers;
  final void Function(List<TextEditingController>) setKeyControllers;
  final List<TextEditingController> Function() getValueControllers;
  final void Function(List<TextEditingController>) setValueControllers;

  final double width;
  @override
  _KeyValuePairsPageState createState() => _KeyValuePairsPageState();
}

class _KeyValuePairsPageState extends State<KeyValuePairsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void addKeyValueControllers() {
    var keyControllers = widget.getKeyControllers();
    var valueControllers = widget.getValueControllers();

    keyControllers.add(TextEditingController());
    valueControllers.add(TextEditingController());

    widget.setKeyControllers(keyControllers);
    widget.setValueControllers(valueControllers);
  }

  void removeKeyValueControllers() {
    var keyControllers = widget.getKeyControllers();
    var valueControllers = widget.getValueControllers();

    keyControllers.removeLast();
    valueControllers.removeLast();

    widget.setKeyControllers(keyControllers);
    widget.setValueControllers(valueControllers);
  }

  Widget keyValueWidget(int index) {
    var valueRegExp = RegExp(r'[a-zA-Z0-9\s\-_\.]*');
    var keyRegExp = RegExp(r'[a-zA-Z0-9\-_\.]*'); // No whitespace either
    const maxLength = 4096;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
            child: TextField(
          key: Key('Key ${index + 1}'),
          inputFormatters: [
            FilteringTextInputFormatter.allow(keyRegExp),
            LengthLimitingTextInputFormatter(maxLength),
          ],
          onChanged: (value) {
            // Because buildHeaderString() builds a static string, whenever the
            // user inputs new text, we must call the following so that setState
            // is called
            widget.setKeyControllers(widget.getKeyControllers());
          },
          controller: widget.getKeyControllers()[index],
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  20), // Increase this value for more rounded corners
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(20), // Also apply for the enabled state
              borderSide: const BorderSide(
                color: Colors.grey, // You can change the border color here
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(20), // And for the focused state
              borderSide: BorderSide(
                width: 3,
                color: Theme.of(context)
                    .colorScheme
                    .primary, // And the border color when the TextField is focused
              ),
            ),
            labelText: 'Key ${index + 1}',
          ),
        )),
        const SizedBox(
          height: 5,
          width: 10,
        ),
        Flexible(
            child: TextField(
          inputFormatters: [
            FilteringTextInputFormatter.allow(valueRegExp),
            LengthLimitingTextInputFormatter(maxLength),
          ],
          key: Key('Value ${index + 1}'),
          onChanged: (value) {
            // Because buildHeaderString() builds a static string, whenever the
            // user inputs new text, we must call the following so that setState
            // is called
            widget.setValueControllers(widget.getValueControllers());
          },
          controller: widget.getValueControllers()[index],
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  20), // Increase this value for more rounded corners
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(20), // Also apply for the enabled state
              borderSide: const BorderSide(
                color: Colors.grey, // You can change the border color here
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(20), // And for the focused state
              borderSide: BorderSide(
                width: 3,
                color: Theme.of(context)
                    .colorScheme
                    .primary, // And the border color when the TextField is focused
              ),
            ),
            labelText: 'Value ${index + 1}',
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 250, // maximum height
            minWidth: widget.width, // minimum width as per your requirement
          ),
          child: Scrollbar(
              thickness: 10,
              trackVisibility: true,
              thumbVisibility: true,
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: 2 * widget.getKeyControllers().length,
                itemBuilder: (context, index) => index % 2 == 0
                    ? keyValueWidget((index / 2).floor())
                    : const SizedBox(
                        height: 10,
                      ),
              )),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ElevatedButton(
                onPressed: () {
                  setState(removeKeyValueControllers);
                },
                child: const Icon(Icons.remove),
              ),
            ),
            const SizedBox(
              height: 5,
              width: 5,
            ),
            ElevatedButton(
              onPressed: () {
                setState(addKeyValueControllers);
              },
              child: const Icon(Icons.add, key: Key("add_header")),
            )
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class LinkedAPIDetailsWidget extends StatefulWidget {
  final Function(String, Map<String, String>) onNextClicked;
  final int step;
  final int steps;

  const LinkedAPIDetailsWidget(
      {super.key,
      required this.onNextClicked,
      required this.step,
      required this.steps});
  @override
  _LinkedAPIDetailsWidgetState createState() => _LinkedAPIDetailsWidgetState();
}

class _LinkedAPIDetailsWidgetState extends State<LinkedAPIDetailsWidget> {
  final apiBaseUrlController = TextEditingController();
  List<TextEditingController> apiKeyKeyControllers = [TextEditingController()];
  List<TextEditingController> apiKeyValueControllers = [
    TextEditingController()
  ];
  bool scanning = true;

  @override
  void initState() {
    super.initState();
  }

  bool allHeadersAreComplete() {
    if (apiKeyKeyControllers.isEmpty) {
      return false;
    }
    for (int i = 0; i < apiKeyKeyControllers.length; i++) {
      if (apiKeyKeyControllers[i].text.isEmpty ||
          apiKeyValueControllers[i].text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  String buildHeaderString() {
    const maxCharsOfKey = 10;
    List<String> lines = [];
    for (int i = 0; i < apiKeyKeyControllers.length; i++) {
      if (apiKeyKeyControllers[i].text.isNotEmpty ||
          apiKeyValueControllers[i].text.isNotEmpty) {
        String key = apiKeyKeyControllers[i].text;
        String value = apiKeyValueControllers[i].text;
        String shortenedValue =
            value.substring(0, min(maxCharsOfKey, value.length));
        String line =
            "'$key: ${value.length > maxCharsOfKey ? "$shortenedValue..." : value}'";
        lines.add(line);
      }
    }
    if (allHeadersAreComplete()) {
      return "Requests will have headers\n\n${lines.join("\n")}";
    }
    return "You must complete all headers";
  }

  @override
  Widget build(BuildContext context) {
    var width = isDesktopResolution(context) ? 600.0 : 250.0;
    return getDialogTemplate(
      step: widget.step,
      steps: widget.steps,
      child: ListView(
        children: [
          const SizedBox(
            height: 100,
          ),
          const Text(
            "What are your APIs details?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
              width: width,
              child: const Text(
                "API base URL:",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              )),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Container()),
            SizedBox(
                width: width,
                child: TextField(
                  key: const Key("api_base_url"),
                  controller: apiBaseUrlController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(
                        r'[^\s]+')), // This regex disallows any whitespace
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          20), // Increase this value for more rounded corners
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          20), // Also apply for the enabled state
                      borderSide: const BorderSide(
                        color:
                            Colors.grey, // You can change the border color here
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          20), // And for the focused state
                      borderSide: BorderSide(
                        width: 3,
                        color: Theme.of(context)
                            .colorScheme
                            .primary, // And the border color when the TextField is focused
                      ),
                    ),
                    labelText: 'URL',
                  ),
                )),
            Flexible(child: Container()),
          ]),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width: width,
            child: const Text(
              "API header:",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
              width: width,
              child: Text(
                "These must not expire.\n",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: isDesktopResolution(context) ? 14 : 12),
              )),
          KeyValuePairsPage(
            width: width,
            setKeyControllers: (value) {
              setState(() {
                apiKeyKeyControllers = value;
              });
            },
            setValueControllers: (value) {
              setState(() {
                apiKeyValueControllers = value;
              });
            },
            getKeyControllers: () => apiKeyKeyControllers,
            getValueControllers: () => apiKeyValueControllers,
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: width,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    buildHeaderString(),
                    style: TextStyle(
                        fontSize: isDesktopResolution(context) ? 18 : 12),
                    softWrap: true,
                    textAlign: TextAlign.start,
                  ),
                ),
              ]),
          const SizedBox(
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () async {
                    gtag(
                        command: "event",
                        target: "BackClicked",
                        parameters: {"from": "LinkedAPIDetailsWidget"});
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: isDesktopResolution(context) ? 25 : 12,
                  ),
                  label: Text(
                    key: const Key("APICredentialsBack"),
                    "Back",
                    style: TextStyle(
                      fontSize: isDesktopResolution(context) ? 25 : 12,
                    ),
                  )),
              const SizedBox(
                width: 16,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4))),
                onPressed: apiBaseUrlController.text.isNotEmpty &&
                        allHeadersAreComplete()
                    ? () {
                        Map<String, String> keyValueMap = {};
                        for (int idx = 0;
                            idx < apiKeyKeyControllers.length;
                            idx++) {
                          keyValueMap[apiKeyKeyControllers[idx].text] =
                              apiKeyValueControllers[idx].text;
                        }
                        gtag(
                            command: "event",
                            target: "NextClicked",
                            parameters: {"from": "LinkedAPIDetailsWidget"});
                        widget.onNextClicked(
                            apiBaseUrlController.text, keyValueMap);
                      }
                    : null,
                icon: Icon(
                  color: Theme.of(context).colorScheme.onPrimary,
                  Icons.navigate_next_outlined,
                  size: isDesktopResolution(context) ? 25 : 12,
                ),
                label: Text(
                  key: const Key("APICredentialsNext"),
                  "Next",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: isDesktopResolution(context) ? 25 : 12,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
      context: context,
    );
  }
}

class DeploymentCostWidget extends StatelessWidget {
  const DeploymentCostWidget(
      {super.key,
      required this.assetEarnings,
      required this.assetEarningsType,
      required this.dhaliEarnings,
      required this.deploymentCost,
      required this.hostingType,
      required this.yesClicked,
      required this.step,
      required this.steps});

  final Function() yesClicked;
  final double deploymentCost;
  final double assetEarnings;
  final ChargingChoice assetEarningsType;
  final HostingChoice hostingType;
  final double dhaliEarnings;
  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      step: step,
      steps: steps,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 16,
          ),
          Text(
            "Here is a break down of the charges:",
            style: TextStyle(fontSize: isDesktopResolution(context) ? 25 : 12),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            "Paid by you:",
            style: TextStyle(
                fontSize: isDesktopResolution(context) ? 25 : 12,
                fontWeight: FontWeight.bold),
          ),
          Table(
            border: TableBorder.all(),
            columnWidths: const <int, TableColumnWidth>{
              0: IntrinsicColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "What?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktopResolution(context) ? 25 : 12,
                        ),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "When?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "Cost (XRP):",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                          isDesktopResolution(context)
                              ? "Deployment cost"
                              : "Deployment\ncost",
                          style: TextStyle(
                              fontSize:
                                  isDesktopResolution(context) ? 25 : 12))),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text("Now",
                          style: TextStyle(
                              fontSize:
                                  isDesktopResolution(context) ? 25 : 12))),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text((deploymentCost / 1000000).toStringAsFixed(4),
                          style: TextStyle(
                              fontSize:
                                  isDesktopResolution(context) ? 25 : 12))),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            "Paid by the user of your asset:",
            textAlign: TextAlign.left,
            style: TextStyle(
                fontSize: isDesktopResolution(context) ? 25 : 12,
                fontWeight: FontWeight.bold),
          ),
          Table(
            border: TableBorder.all(),
            columnWidths: const <int, TableColumnWidth>{
              0: IntrinsicColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "What?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "When?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "Cost (XRP):",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        isDesktopResolution(context)
                            ? "Dhali's earnings"
                            : "Dhali's\nearnings",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        isDesktopResolution(context)
                            ? "When API is used"
                            : "When API\nis used",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "${(dhaliEarnings / 100 * assetEarnings).toStringAsFixed(5)} per ${assetEarningsType == ChargingChoice.perRequest ? "request" : "second"}",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        isDesktopResolution(context)
                            ? "Your earnings"
                            : "Your\nearnings",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        isDesktopResolution(context)
                            ? "When API is used"
                            : "When API\nis used",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "${assetEarnings.toStringAsFixed(5)} per ${assetEarningsType == ChargingChoice.perRequest ? "request" : "second"}",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        isDesktopResolution(context)
                            ? "Total cost"
                            : "Total\ncost",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        isDesktopResolution(context)
                            ? "When API is used"
                            : "When API\nis used",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "${(dhaliEarnings / 100 * assetEarnings + assetEarnings).toStringAsFixed(5)} per ${assetEarningsType == ChargingChoice.perRequest ? "request" : "second"}",
                        style: TextStyle(
                            fontSize: isDesktopResolution(context) ? 25 : 12),
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 32,
          ),
          Text(
            "Are you sure you want to deploy?",
            style: TextStyle(fontSize: isDesktopResolution(context) ? 25 : 12),
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () async {
                    gtag(
                        command: "event",
                        target: "BackClicked",
                        parameters: {"from": "DeploymentCostWidget"});
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: isDesktopResolution(context) ? 25 : 12,
                  ),
                  label: Text(
                    key: const Key("DeploymentCostWidgetBack"),
                    "Back",
                    style: TextStyle(
                        fontSize: isDesktopResolution(context) ? 25 : 12),
                  )),
              const SizedBox(
                width: 16,
              ),
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () {
                    gtag(
                        command: "event",
                        target: "YesClicked",
                        parameters: {"from": "DeploymentCostWidget"});
                    yesClicked();
                  },
                  icon: Icon(
                    color: Theme.of(context).colorScheme.onPrimary,
                    Icons.done_outline_rounded,
                    size: isDesktopResolution(context) ? 25 : 12,
                  ),
                  label: Text(
                    "Yes",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: isDesktopResolution(context) ? 25 : 12),
                  )),
              const SizedBox(
                width: 32,
              ),
            ],
          ),
        ],
      ),
      context: context,
    );
  }
}

class DataTransmissionWidget extends StatefulWidget {
  final List<DataEndpointPair> data;
  final Function(List<DataEndpointPair>) onNextClicked;
  final Function()? onExitClicked;
  final BaseRequest Function<T extends BaseRequest>(String method, String path)
      getRequest;
  final Widget? Function(BuildContext context, BaseResponse?)?
      getOnSuccessWidget;

  final GetUploader getUploader;

  final Map<String, String> payment;

  const DataTransmissionWidget({
    super.key,
    required this.data,
    required this.onNextClicked,
    required this.getRequest,
    required this.payment,
    required this.getUploader,
    required this.getOnSuccessWidget,
    this.onExitClicked,
  });

  @override
  _DataTransmissionWidgetState createState() => _DataTransmissionWidgetState();
}

class _DataTransmissionWidgetState extends State<DataTransmissionWidget> {
  String? currentFileUploading;
  int currentFileIndexUploading = 1;
  bool deploying = true;
  bool uploadWasSuccessful = false;
  int? responseCode;
  BaseResponse? response;
  double progressBarPercentage = 0;
  late BaseUploader uploadRequest;
  String? sessionID;

  @override
  void initState() {
    currentFileUploading = widget.data[0].data.fileName;
    super.initState();

    var logger = Logger();

    bool shouldContinue = true;

    Future.forEach(widget.data, (element) async {
      if (!shouldContinue) {
        return; // Skip the rest of the iterations if flag is set
      }

      var castedElement = element as DataEndpointPair;
      response = await uploader(
          castedElement.data, widget.payment, castedElement.endPoint,
          sessionID: sessionID);
      if (response == null ||
          (response!.statusCode != 200 && response!.statusCode != 308)) {
        shouldContinue = false;
      }
      try {
        sessionID = response!
            .headers[Config.config!["DHALI_ID"].toString().toLowerCase()];
      } on FormatException catch (_) {
        return;
      } catch (e, stacktrace) {
        logger.e("Unexpected response from asset deployment, with error: $e "
            "and stacktrace: $stacktrace");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      child: deploying ||
              !uploadWasSuccessful ||
              widget.getOnSuccessWidget == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: isDesktopResolution(context) ? 16 : 8,
                ),
                LinearProgressIndicator(
                  value: progressBarPercentage,
                  semanticsLabel: 'Linear progress indicator',
                ),
                SizedBox(
                  height: isDesktopResolution(context) ? 16 : 8,
                ),
                deploying
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            key: const Key("deploying_in_progress_dialog"),
                            textAlign: TextAlign.center,
                            "Uploading '${currentFileUploading.toString()}: "
                            "file $currentFileIndexUploading of ${widget.data.length}'."
                            "\nPlease wait.",
                            style: TextStyle(
                              fontSize: isDesktopResolution(context) ? 30 : 15,
                            ),
                          ),
                          SizedBox(
                              height: isDesktopResolution(context) ? 20 : 10),
                          const CircularProgressIndicator(),
                        ],
                      )
                    : responseCode == 200
                        ? Text(
                            key: const Key("upload_success_info"),
                            "Your upload was successful",
                            style: TextStyle(
                                fontSize:
                                    isDesktopResolution(context) ? 30 : 15),
                          )
                        : Text(
                            key: const Key("upload_failed_warning"),
                            textAlign: TextAlign.center,
                            "Upload failed"
                            "\nStatus code: ${responseCode.toString()}"
                            "\nReason: ${response!.reasonPhrase}",
                            style: TextStyle(
                                fontSize:
                                    isDesktopResolution(context) ? 30 : 15),
                          ),
                SizedBox(
                  height: isDesktopResolution(context) ? 16 : 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical:
                                    isDesktopResolution(context) ? 20 : 10,
                                horizontal:
                                    isDesktopResolution(context) ? 20 : 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        onPressed: () {
                          if (widget.onExitClicked != null) {
                            widget.onExitClicked!();
                          }
                          if (deploying) {
                            gtag(
                                command: "event",
                                target: "CancelClicked",
                                parameters: {"from": "DataTransmissionWidget"});
                            uploadRequest.cancelUpload();
                            setState(() {
                              deploying = false;
                              uploadWasSuccessful = false;
                            });
                          } else {
                            gtag(
                                command: "event",
                                target: "ExitClicked",
                                parameters: {"from": "DataTransmissionWidget"});
                            Navigator.of(context).popUntil((route) {
                              // Here, we assume that a Dialog doesn't have a route name (which is true by default).
                              // If you've given a custom name to your Dialog route, check against that name instead.
                              return route.settings.name != null;
                            });
                          }
                        },
                        icon: Icon(
                          responseCode == 200
                              ? Icons.done_outline_rounded
                              : Icons.close_outlined,
                          size: isDesktopResolution(context) ? 32 : 16,
                        ),
                        label: Text(
                          key: const Key("exit_deployment_dialogs"),
                          deploying ? "Cancel" : "Exit",
                          style: TextStyle(
                              fontSize: isDesktopResolution(context) ? 30 : 15),
                        )),
                  ],
                )
              ],
            )
          : uploadWasSuccessful
              ? widget.getOnSuccessWidget!(context, response)!
              : uploadFailed(context, responseCode!),
      context: context,
    );
  }

  Future<BaseResponse?> uploader(
      AssetModel file, Map<String, String> payment, String path,
      {String? sessionID}) async {
    uploadRequest = widget.getUploader(
        payment: const JsonEncoder().convert(payment),
        getRequest: widget.getRequest,
        progressStatus: (progressPercentage) {
          setState(() {
            currentFileUploading = file.fileName;
            progressBarPercentage = progressPercentage;
            if (progressPercentage >= 1) {
              currentFileIndexUploading += 1;
            }
          });
        },
        model: file,
        maxChunkSize: Config.config!["MAX_NUMBER_OF_BYTES_PER_DEPLOY_CHUNK"]);

    final response = await uploadRequest.upload(path, sessionID: sessionID)
        as StreamedResponse?;

    setState(() {
      if (response == null) {
        return;
      }
      responseCode = response.statusCode;
      if (responseCode != 200) {
        deploying = false;
        uploadWasSuccessful = false;
        return;
      } else {
        if (currentFileIndexUploading > widget.data.length) {
          deploying = false;
          uploadWasSuccessful = true;
          return;
        } else {
          deploying = true;
          uploadWasSuccessful = true;
          return;
        }
      }
    });
    return response;
  }
}

Widget uploadFailed(BuildContext context, int responseCode, {String? reason}) {
  gtag(
      command: "event",
      target: "UploadFailed",
      parameters: {"errorCode": responseCode.toString()});
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.close_outlined,
          color: Colors.red,
          size: 80,
        ),
        Text(
          key: const Key("upload_failed_warning"),
          textAlign: TextAlign.center,
          "Deployment failed: status code ${responseCode.toString()}${reason != null ? " reason: $reason" : ""}",
          style: const TextStyle(fontSize: 30),
        ),
        const SizedBox(
          height: 16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4))),
                onPressed: () {
                  Navigator.of(context).popUntil((route) {
                    // Here, we assume that a Dialog doesn't have a route name (which is true by default).
                    // If you've given a custom name to your Dialog route, check against that name instead.
                    return route.settings.name != null;
                  });
                },
                icon: const Icon(
                  Icons.close_outlined,
                  size: 32,
                ),
                label: const Text(
                  key: Key("exit_deployment_dialogs"),
                  "Exit",
                  style: TextStyle(fontSize: 30),
                )),
          ],
        ),
      ],
    ),
  );
}

Widget NFTUploadingWidget(
    BuildContext context,
    FirebaseFirestore? Function() getFirestore,
    void Function(String nfTokenId) onNFTOfferPoll,
    String? Function() getSessionID,
    {void Function()? onExitClicked}) {
  var nfTokenIdStream = getFirestore()!
      .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
      .doc(getSessionID())
      .snapshots();

  return StreamBuilder(
      stream: nfTokenIdStream,
      builder: (BuildContext _,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Minting API\'s NFT: This may take a minute or two. Please wait.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  key: Key("minting_nft_spinner"),
                ),
              ],
            ),
          );
        }

        var data = snapshot.data!.data()!;

        onNFTOfferPoll(
            data[Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]]);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.done_outline_rounded,
                color: Colors.green,
                size: 80,
              ),
              Text(
                key: const Key("upload_success_info"),
                "Your NFT was successfully minted.",
                style:
                    TextStyle(fontSize: isDesktopResolution(context) ? 30 : 18),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4))),
                      onPressed: () {
                        if (onExitClicked != null) {
                          onExitClicked();
                        }
                        Navigator.of(context).popUntil((route) {
                          // Here, we assume that a Dialog doesn't have a route name (which is true by default).
                          // If you've given a custom name to your Dialog route, check against that name instead.
                          return route.settings.name != null;
                        });
                      },
                      icon: const Icon(
                        Icons.done_outline_rounded,
                        size: 32,
                      ),
                      label: const Text(
                        key: Key("exit_deployment_dialogs"),
                        "Exit",
                        style: TextStyle(fontSize: 30),
                      )),
                ],
              ),
            ],
          ),
        );
      });
}

class InferenceCostWidget extends StatelessWidget {
  const InferenceCostWidget(
      {super.key,
      required this.file,
      required this.inferenceCost,
      required this.yesClicked,
      required this.step,
      required this.steps});

  final Function(AssetModel, double) yesClicked;
  final AssetModel file;
  final double inferenceCost;
  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      step: step,
      steps: steps,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 16,
          ),
          Text(
            "Running this API typically costs ${(inferenceCost / 1000000).toStringAsFixed(4)} XRP",
            style: TextStyle(fontSize: isDesktopResolution(context) ? 25 : 12),
          ),
          Text(
            "Are you sure you want to continue?",
            style: TextStyle(fontSize: isDesktopResolution(context) ? 25 : 12),
          ),
          SizedBox(
            height: isDesktopResolution(context) ? 16 : 8,
            width: isDesktopResolution(context) ? 16 : 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                          vertical: isDesktopResolution(context) ? 20 : 10,
                          horizontal: isDesktopResolution(context) ? 20 : 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () async {
                    gtag(
                        command: "event",
                        target: "NoClicked",
                        parameters: {"from": "InferenceCostWidget"});
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.close_outlined,
                    size: isDesktopResolution(context) ? 32 : 16,
                  ),
                  label: Text(
                    "No",
                    style: TextStyle(
                        fontSize: isDesktopResolution(context) ? 30 : 15),
                  )),
              SizedBox(
                width: isDesktopResolution(context) ? 16 : 8,
              ),
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                          vertical: isDesktopResolution(context) ? 20 : 10,
                          horizontal: isDesktopResolution(context) ? 20 : 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () {
                    gtag(
                        command: "event",
                        target: "YesClicked",
                        parameters: {"from": "InferenceCostWidget"});
                    yesClicked(file, inferenceCost);
                  },
                  icon: Icon(
                    color: Theme.of(context).colorScheme.onPrimary,
                    Icons.done_outline_rounded,
                    size: isDesktopResolution(context) ? 32 : 16,
                  ),
                  label: Text(
                    "Yes",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: isDesktopResolution(context) ? 30 : 15),
                  )),
              const SizedBox(
                width: 32,
              ),
            ],
          ),
        ],
      ),
      context: context,
    );
  }
}

Widget getDialog(BuildContext context, {required Widget child}) {
  return Dialog(
      insetPadding: EdgeInsets.all(isDesktopResolution(context) ? 50 : 10),
      child: child);
}

Widget getDialogTemplate(
    {required Widget child,
    required BuildContext context,
    int? step,
    int? steps}) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktopResolution(context) ? 80 : 10),
              child: child,
            ),
          ),
        ),
      ),
      Positioned(
        right: isDesktopResolution(context) ? 55 : 25,
        top: 15,
        child: IconButton(
          icon: Icon(Icons.close, size: isDesktopResolution(context) ? 60 : 30),
          onPressed: () {
            gtag(command: "event", target: "DialogClosed");
            Navigator.of(context).popUntil((route) {
              // Here, we assume that a Dialog doesn't have a route name (which is true by default).
              // If you've given a custom name to your Dialog route, check against that name instead.
              return route.settings.name != null;
            });
          },
        ),
      ),
      if (step != null && steps != null)
        Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(
            height: 40,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              "Step $step of $steps",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 20,
          )
        ]),
    ],
  );
}
