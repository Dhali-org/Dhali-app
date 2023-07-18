import 'dart:async';
import 'dart:convert';

import "package:universal_html/html.dart" as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/utils/show_popup_text_with_link.dart';
import 'package:dotted_border/dotted_border.dart';
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

  const DropzoneRunWidget(
      {Key? key, required this.onDroppedFile, required this.onNextClicked})
      : super(key: key);
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
                          fontSize: isDesktopResolution(context) ? 20 : 10,
                          color: isHighlighted
                              ? AppTheme.nearlyWhite
                              : AppTheme.nearlyBlack),
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
                              ? AppTheme.nearlyWhite
                              : AppTheme.nearlyBlack),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 20),
                            backgroundColor: AppTheme.dhali_blue,
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
                          Icons.navigate_next_outlined,
                          size: isDesktopResolution(context) ? 32 : 16,
                        ),
                        label: Text(
                          "Next",
                          style: TextStyle(
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
            backgroundColor: color,
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
          if (controller != null) {
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

class DropzoneDeployWidget extends StatefulWidget {
  final ValueChanged<AssetModel> onDroppedFile;
  final Function(AssetModel, AssetModel) onNextClicked;

  const DropzoneDeployWidget(
      {Key? key, required this.onDroppedFile, required this.onNextClicked})
      : super(key: key);
  @override
  _DropzoneDeployWidgetState createState() => _DropzoneDeployWidgetState();
}

class _DropzoneDeployWidgetState extends State<DropzoneDeployWidget> {
  DropzoneViewController? controller;
  bool isHighlighted = false;
  AssetModel? assetFile;
  AssetModel? readmeFile;
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
                      assetFile != null
                          ? "Selected asset file: ${assetFile!.fileName}"
                          : "No .tar docker image asset selected",
                      style: TextStyle(
                          fontSize: 20,
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
                                "Please provide a docker image file in '.tar' format.  For instructions, see",
                            urlText: "here.",
                            url:
                                "https://dhali.io/docs/#/?id=creating-dhali-assets",
                            context: context);
                      },
                      icon: const Icon(
                        Icons.help_outline_outlined,
                        size: 32,
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    assetFile != null
                        ? const Icon(
                            Icons.done_outline_rounded,
                            color: Colors.green,
                            size: 80,
                          )
                        : Container()
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      readmeFile != null
                          ? "Selected markdown file: ${readmeFile!.fileName}"
                          : "No .md asset description selected",
                      style: TextStyle(
                          fontSize: 20,
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
                            parameters: {"forAction": "README.md upload"});
                        showPopupTextWithLink(
                            text:
                                "Please provide a 'README.md' file documenting your asset.  For more information, see ",
                            urlText: "here.",
                            url:
                                "https://dhali.io/docs/#/?id=creating-dhali-assets",
                            context: context);
                      },
                      icon: const Icon(
                        Icons.help_outline_outlined,
                        size: 32,
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    readmeFile != null
                        ? const Icon(
                            Icons.done_outline_rounded,
                            color: Colors.green,
                            size: 80,
                          )
                        : Container()
                  ],
                ),
                const Icon(
                  Icons.cloud_upload_rounded,
                  color: AppTheme.dhali_blue,
                  size: 80,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      "Drag or select your files",
                      style: TextStyle(
                          fontSize: 30,
                          color: isHighlighted
                              ? AppTheme.nearlyWhite
                              : AppTheme.nearlyBlack),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                TextField(
                  key: const Key('asset_name_input_field'),
                  onChanged: (value) => setState(() {
                    if (assetFile != null) {
                      assetFile!.modelName = textController.text;
                      readmeFile!.modelName = textController.text;
                    }
                  }),
                  controller: textController,
                  maxLength: 64,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 20),
                    helperStyle: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                    helperText: "What your asset will be called",
                    labelText: "Asset name",
                    hintText: "Enter the name you'd like for your asset "
                        "(a-z, 0-9, -, .)",
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("([a-z0-9-]+)"))
                  ],
                ),
                const SizedBox(
                  width: 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getFileUploadButton(
                        const Key("choose_docker_image_button"),
                        "Choose .tar file",
                        ["application/x-tar"],
                        AppTheme.secondary),
                    const SizedBox(
                      width: 16,
                    ),
                    getFileUploadButton(
                        const Key("choose_readme_button"),
                        "Choose .md file",
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 20),
                            backgroundColor: AppTheme.dhali_blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        onPressed: assetFile != null &&
                                readmeFile != null &&
                                textController.text != ""
                            ? () async {
                                gtag(
                                    command: "event",
                                    target: "NextClicked",
                                    parameters: {
                                      "from": "DropZoneDeployWidget"
                                    });
                                widget.onNextClicked(assetFile!, readmeFile!);
                              }
                            : null,
                        icon: const Icon(
                          Icons.navigate_next_outlined,
                          size: 32,
                        ),
                        label: const Text(
                          "Next",
                          style: TextStyle(fontSize: 30),
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            backgroundColor: color,
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
          if (controller != null) {
            final events = await controller!.pickFiles(mime: mime);
            if (events.isEmpty) return;
            acceptFile(events.first);
          } else {
            // TODO : This should be injectable
            acceptFile(html.File(
                [1, 2, 3, 4, 5, 6, 7], "test.tar", {"type": mime[0]}));
          }
        },
        icon: const Icon(
          Icons.search,
          size: 32,
        ),
        label: Text(
          text,
          style: const TextStyle(fontSize: 30),
        ));
  }

  Future acceptFile(dynamic event) async {
    final fileName = event.name;

    String mime = event.type;
    int bytes = event.size;
    if (mime == "application/x-tar") {
      assetFile = AssetModel(
          imageFile: event,
          fileName: fileName,
          modelName: textController.text,
          mime: mime,
          size: bytes);
      widget.onDroppedFile(assetFile!);
    } else if (mime == "text/markdown") {
      readmeFile = AssetModel(
          imageFile: event,
          fileName: fileName,
          modelName: textController.text,
          mime: mime,
          size: bytes);
      widget.onDroppedFile(readmeFile!);
    }
    setState(() {
      isHighlighted = false;
    });
  }
}

class ImageScanningWidget extends StatefulWidget {
  final AssetModel file;
  final ValueChanged<AssetModel> onNextClicked;

  const ImageScanningWidget(
      {Key? key, required this.file, required this.onNextClicked})
      : super(key: key);
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
                  style: const TextStyle(
                      fontSize: 30, color: AppTheme.nearlyBlack),
                )
              : scanSuccess
                  ? const Text(
                      "Your image was successfully scanned.",
                      style:
                          TextStyle(fontSize: 30, color: AppTheme.nearlyBlack),
                    )
                  : const Text(
                      textAlign: TextAlign.center,
                      "Image invalid: "
                      "\nFollow the guide for preparing your "
                      "image <here>.",
                      style:
                          TextStyle(fontSize: 30, color: AppTheme.nearlyBlack),
                    ),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                backgroundColor: AppTheme.dhali_blue,
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
            icon: const Icon(
              Icons.navigate_next_outlined,
              size: 32,
            ),
            label: const Text(
              "Next",
              style: TextStyle(fontSize: 30),
            ),
          ),
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

class ImageCostWidget extends StatefulWidget {
  final AssetModel file;

  final Function(AssetModel, double) onNextClicked;
  final int? defaultEarningsPerInference;

  const ImageCostWidget(
      {Key? key,
      required this.file,
      required this.onNextClicked,
      this.defaultEarningsPerInference})
      : super(key: key);
  @override
  _ImageCostWidgetState createState() => _ImageCostWidgetState();
}

class _ImageCostWidgetState extends State<ImageCostWidget> {
  final controller = TextEditingController();
  bool scanning = true;

  @override
  void initState() {
    super.initState();
    controller.text = widget.defaultEarningsPerInference != null
        ? widget.defaultEarningsPerInference.toString()
        : controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            textAlign: TextAlign.center,
            "Set your earning rate per inference.",
            style: TextStyle(fontSize: 30, color: AppTheme.nearlyBlack),
          ),
          const Text(
            textAlign: TextAlign.center,
            "\nKeep this small to encourage usage.\n",
            style: TextStyle(fontSize: 20, color: AppTheme.nearlyBlack),
          ),
          const Text(
            textAlign: TextAlign.center,
            "Example: If running your asset costs Dhali \$1 in compute costs per inference, by setting 20 below you will earn \$0.20 per inference.",
            style: TextStyle(fontSize: 20, color: AppTheme.nearlyBlack),
          ),
          const SizedBox(
            height: 16,
          ),
          TextField(
            key: const Key("percentage_earnings_input"),
            onChanged: (value) => setState(() {}),
            controller: controller,
            maxLength: 5,
            // ignore: prefer_const_constructors
            decoration: InputDecoration(
              labelStyle: const TextStyle(fontSize: 20),
              helperStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
              helperText: "Percentage you earn above Dhali compute costs",
              hintText: "Enter a percentage (e.g., '20')",
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ], // Only numbers can be entered
          ),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                backgroundColor: AppTheme.dhali_blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))),
            onPressed: controller.text.isNotEmpty
                ? () {
                    gtag(
                        command: "event",
                        target: "NextClicked",
                        parameters: {"from": "ImageCostWidget"});
                    widget.onNextClicked(
                        widget.file,
                        double.tryParse(controller
                            .text)!); // != null because input "digitsOnly"
                  }
                : null,
            icon: const Icon(
              Icons.navigate_next_outlined,
              size: 32,
            ),
            label: const Text(
              "Next",
              style: TextStyle(fontSize: 30),
            ),
          ),
        ],
      ),
      context: context,
    );
  }
}

class DeploymentCostWidget extends StatelessWidget {
  const DeploymentCostWidget(
      {Key? key,
      required this.file,
      required this.assetEarnings,
      required this.dhaliEarnings,
      required this.deploymentCost,
      required this.yesClicked})
      : super(key: key);

  final Function(AssetModel, double) yesClicked;
  final AssetModel file;
  final double deploymentCost;
  final double assetEarnings;
  final double dhaliEarnings;

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 16,
          ),
          const Text(
            "Here is a break down of the asset's costs:",
            style: TextStyle(fontSize: 25, color: AppTheme.nearlyBlack),
          ),
          const SizedBox(
            height: 16,
          ),
          const Text(
            "Paid by you:",
            style: TextStyle(
                fontSize: 30,
                color: AppTheme.nearlyBlack,
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
                      child: const Text(
                        "What?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "When?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "Cost: XRP",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("Deployment cost")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("Now")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child:
                          Text((deploymentCost / 1000000).toStringAsFixed(4))),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          const Text(
            "Paid by the user of your asset:",
            textAlign: TextAlign.left,
            style: TextStyle(
                fontSize: 30,
                color: AppTheme.nearlyBlack,
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
                      child: const Text(
                        "What?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "When?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "Cost: percentage of compute costs",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("Dhali's earnings")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("When asset is used")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text("$dhaliEarnings%")),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("Your earnings")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("When asset is used")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text("$assetEarnings%")),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("Total cost per inference")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("When asset is used")),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: Text("${100 + dhaliEarnings + assetEarnings}%")),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          const Text(
            "If you continue, the above costs will be applied.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, color: AppTheme.nearlyBlack),
          ),
          const SizedBox(
            height: 16,
          ),
          const SizedBox(
            height: 16,
          ),
          const Text(
            "Are you sure you want to deploy?",
            style: TextStyle(fontSize: 25, color: AppTheme.nearlyBlack),
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
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 32,
                  ),
                  label: const Text(
                    "Back",
                    style: TextStyle(fontSize: 30),
                  )),
              const SizedBox(
                width: 16,
              ),
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      backgroundColor: AppTheme.dhali_blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () {
                    gtag(
                        command: "event",
                        target: "YesClicked",
                        parameters: {"from": "DeploymentCostWidget"});
                    yesClicked(file, assetEarnings);
                  },
                  icon: const Icon(
                    Icons.done_outline_rounded,
                    size: 32,
                  ),
                  label: const Text(
                    "Yes",
                    style: TextStyle(fontSize: 30),
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
  final BaseRequest Function(String method, String path) getRequest;
  final Widget? Function(BuildContext context, BaseResponse?)
      getOnSuccessWidget;

  final GetUploader getUploader;

  final Map<String, String> payment;

  const DataTransmissionWidget(
      {Key? key,
      required this.data,
      required this.onNextClicked,
      required this.getRequest,
      required this.payment,
      required this.getUploader,
      required this.getOnSuccessWidget})
      : super(key: key);

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

    Future.forEach(widget.data, (element) async {
      var castedElement = element as DataEndpointPair;
      response = await uploader(
          castedElement.data, widget.payment, castedElement.endPoint,
          sessionID: sessionID);
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
              widget.getOnSuccessWidget(context, response) == null
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
                                fontSize:
                                    isDesktopResolution(context) ? 30 : 15,
                                color: AppTheme.nearlyBlack),
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
                                    isDesktopResolution(context) ? 30 : 15,
                                color: AppTheme.nearlyBlack),
                          )
                        : Text(
                            key: const Key("upload_failed_warning"),
                            textAlign: TextAlign.center,
                            "Upload failed"
                            "\nStatus code: ${responseCode.toString()}"
                            "\nReason: ${response!.reasonPhrase}",
                            style: TextStyle(
                                fontSize:
                                    isDesktopResolution(context) ? 30 : 15,
                                color: AppTheme.nearlyBlack),
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
                            backgroundColor: AppTheme.dhali_blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        onPressed: () {
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
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
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
              ? widget.getOnSuccessWidget(context, response)!
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

Widget uploadFailed(BuildContext context, int responseCode) {
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
          "Deployment failed: status code "
          "${responseCode.toString()}",
          style: const TextStyle(fontSize: 30, color: AppTheme.nearlyBlack),
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
                    backgroundColor: AppTheme.dhali_blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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
    String? Function() getSessionID) {
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
                  'Minting asset NFT: This may take a minute or two. Please wait.',
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
              const Text(
                key: Key("upload_success_info"),
                "Your NFT was successfully minted.",
                style: TextStyle(fontSize: 30, color: AppTheme.nearlyBlack),
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
                          backgroundColor: AppTheme.dhali_blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4))),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
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
      {Key? key,
      required this.file,
      required this.inferenceCost,
      required this.yesClicked})
      : super(key: key);

  final Function(AssetModel, double) yesClicked;
  final AssetModel file;
  final double inferenceCost;

  @override
  Widget build(BuildContext context) {
    return getDialogTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 16,
          ),
          Text(
            "Running this asset typically costs $inferenceCost drops",
            style: TextStyle(
                fontSize: isDesktopResolution(context) ? 25 : 12,
                color: AppTheme.nearlyBlack),
          ),
          Text(
            "Are you sure you want to continue?",
            style: TextStyle(
                fontSize: isDesktopResolution(context) ? 25 : 12,
                color: AppTheme.nearlyBlack),
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
                      padding: EdgeInsets.symmetric(
                          vertical: isDesktopResolution(context) ? 20 : 10,
                          horizontal: isDesktopResolution(context) ? 20 : 10),
                      backgroundColor: AppTheme.secondary,
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
                      padding: EdgeInsets.symmetric(
                          vertical: isDesktopResolution(context) ? 20 : 10,
                          horizontal: isDesktopResolution(context) ? 20 : 10),
                      backgroundColor: AppTheme.dhali_blue,
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
                    Icons.done_outline_rounded,
                    size: isDesktopResolution(context) ? 32 : 16,
                  ),
                  label: Text(
                    "Yes",
                    style: TextStyle(
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

Widget getDialogTemplate(
    {required Widget child, required BuildContext context}) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          color: AppTheme.nearlyWhite,
          child: DottedBorder(
            dashPattern: const [10, 10],
            radius: const Radius.circular(20),
            strokeWidth: 6,
            borderType: BorderType.RRect,
            color: AppTheme.nearlyBlack,
            padding: EdgeInsets.zero,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktopResolution(context) ? 80 : 40),
                child: child,
              ),
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
            Navigator.of(context).pop();
          },
        ),
      ),
    ],
  );
}
