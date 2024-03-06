import 'dart:convert';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/config.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali/utils/api_administration_client.dart';
import 'package:dhali/utils/display_utils.dart';
import 'package:dhali/utils/row_else_column.dart';
import 'package:dhali/utils/show_popup_text_with_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import "package:universal_html/html.dart" as html;
import 'package:web_socket_channel/web_socket_channel.dart';

enum DialogDirection { next, back, cancel }

Future<void> administrateEntireAPI(
    {required BuildContext context,
    required FirebaseFirestore? Function() getDb,
    required Map<String, String>? Function() getApiHeaders,
    required String? Function() getBaseUrl,
    required String Function() getApiUuid,
    required String? Function() getApiName,
    required double? Function() getEarningRate,
    required ChargingChoice? Function() getEarningType,
    required AssetModel? Function() getDocs,
    required void Function(Map<String, String>) setApiHeaders,
    required void Function(String) setBaseUrl,
    required void Function(String) setApiName,
    required void Function(double) setEarningRate,
    required void Function(ChargingChoice) setEarningType,
    required WebSocketChannel Function(String) getWebSocketChannel,
    required void Function(String, String) displayQrAuth,
    required void Function(AssetModel?) setDocs}) async {
  bool? retry = true;
  while (retry == true) {
    retry = false; // Set to false to avoid infinite looping
    //   // If the user wants to retry, they can select at the end
    try {
      var prefilledPublicFuture = prefillPublicMetadata(
          getDb: getDb,
          assetUuid: getApiUuid(),
          setAssetName: setApiName,
          setChargingChoice: setEarningType,
          setEarningRate: setEarningRate);
      var adminGatewayClient = APIAdminGatewayClient(
          onAuthFailure: () {
            showErrorDialog(
                context: context, text: "Failed to authorise API ownership");
          },
          uuid: getApiUuid(),
          getWebSocketChannel: getWebSocketChannel,
          displayQrAuth: displayQrAuth,
          prefillHeaders: (List<dynamic> headers) {
            Map<String, String> combinedMap = {};

            for (var map in headers) {
              map.forEach((key, value) {
                // Ensure the value is actually a String, or convert/cast it as needed
                combinedMap[key] = value.toString();
              });
            }
            setApiHeaders(combinedMap);
          },
          prefillBaseUrl: (String baseUrl) {
            setBaseUrl(baseUrl);
          },
          onUpdated: (List<dynamic> successfulUpdateKeys,
              List<dynamic> failedUpdateKeys) async {});

      var prefilledPrivateFuture =
          adminGatewayClient.connectAndPrefillPrivateMetadata();

      var prefilledFuture =
          Future.wait([prefilledPublicFuture, prefilledPrivateFuture]);

      bool? retrySelected = await showWaitingOnFutureDialog(
          context: context, future: prefilledFuture, isRetryable: true);

      if (retrySelected == true) {
        retry = true;
        continue;
      } else if (retrySelected == false) {
        retry = false;
        break;
      }

      Future<bool> updateRequestedFuture = displayAdminJourney(
          context: context,
          getApiHeaders: () => getApiHeaders()!,
          getBaseUrl: () => getBaseUrl()!,
          getApiName: () => getApiName()!,
          getEarningRate: () => getEarningRate()!,
          getEarningType: () => getEarningType()!,
          getDocs: getDocs,
          setApiHeaders: setApiHeaders,
          setBaseUrl: setBaseUrl,
          setApiName: setApiName,
          setEarningRate: setEarningRate,
          setEarningType: setEarningType,
          setDocs: setDocs);

      await updateRequestedFuture.then((updateRequested) async {
        if (updateRequested) {
          Future<void> submitUpdates({String? docs}) async {
            final updatesSubmittedFuture = adminGatewayClient.submitUpdates(
                apiHeaders: getApiHeaders(),
                baseUrl: getBaseUrl(),
                apiName: getApiName(),
                earningRate: getEarningRate() == null
                    ? null
                    : getEarningRate()! * 1000000,
                earningType: getEarningType(),
                docs: docs);
            await showWaitingOnFutureDialog(
                context: context, future: updatesSubmittedFuture);

            await updatesSubmittedFuture.then((updates) async {
              if (updates == null) {
                return;
              }
              await showOnUpdatedDialog(
                  context: context,
                  failedUpdateKeys: updates["failed_updates"]!,
                  successfulUpdateKeys: updates["successful_updates"]!);
            });
          }

          if (getDocs() != null) {
            FileReader reader = FileReader();
            reader.readAsText(getDocs()!.imageFile);
            reader.onLoadEnd.first.then((_) async {
              String docs =
                  reader.result as String; // This string is utf-8 encoded
              await submitUpdates(docs: docs);
            });
          } else {
            await submitUpdates();
          }
        }
      });
    } catch (e) {
      retry = await showRetryDialog(
          context: context, text: "Would you like to retry?");
    }
  }
}

Future<void> prefillPublicMetadata({
  required FirebaseFirestore? Function() getDb,
  required String assetUuid,
  void Function(String assetName)? setAssetName,
  void Function(ChargingChoice chargingChoice)? setChargingChoice,
  void Function(double earningRate)? setEarningRate,
}) async {
  final publicMetadataSnapshot = await getDb()!
      .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
      .doc(assetUuid)
      .get();
  if (publicMetadataSnapshot.exists && publicMetadataSnapshot.data() != null) {
    final publicMetadata = publicMetadataSnapshot.data()!;

    final remoteAssetName = publicMetadata[
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]];
    final remoteChargingChoice = publicMetadata[
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_TYPE"]];
    final remoteEarningRate = publicMetadata[
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_RATE"]];

    if (setAssetName != null) {
      setAssetName(remoteAssetName);
    }
    if (setEarningRate != null) {
      setEarningRate(remoteEarningRate / 1000000);
    }
    if (setChargingChoice != null) {
      if (remoteChargingChoice == "per_second") {
        setChargingChoice(ChargingChoice.perSecond);
      } else if (remoteChargingChoice == "per_request") {
        setChargingChoice(ChargingChoice.perRequest);
      }
    }
  }
}

Future<bool> displayAdminJourney(
    {required BuildContext context,
    required Map<String, String> Function() getApiHeaders,
    required String Function() getBaseUrl,
    required String Function() getApiName,
    required double Function() getEarningRate,
    required ChargingChoice Function() getEarningType,
    required AssetModel? Function() getDocs,
    required void Function(Map<String, String>) setApiHeaders,
    required void Function(String) setBaseUrl,
    required void Function(String) setApiName,
    required void Function(double) setEarningRate,
    required void Function(ChargingChoice) setEarningType,
    required void Function(AssetModel?) setDocs}) async {
  final journey = [
    (step, steps) async => await showAssetNameAdminDialog(
        context: context,
        currentAssetName: getApiName(),
        step: step,
        steps: steps,
        setNewAssetName: (name) {
          setApiName(name);
        }),
    (step, steps) async => await showEarningsAdminDialog(
        context: context,
        currentEarningsRate: getEarningRate(),
        currentChargingChoice: getEarningType(),
        step: step,
        steps: steps,
        setNewChargingStrategy: (rate, choice) {
          setEarningRate(rate);
          setEarningType(choice);
        }),
    (step, steps) async => await showCredentialsAdminDialog(
        context: context,
        currentBaseUrl: getBaseUrl(),
        currentHeaders: getApiHeaders(),
        step: step,
        steps: steps,
        setNewCredentials: (url, headers) {
          setBaseUrl(url);
          setApiHeaders(headers);
        }),
    (step, steps) async => await showReadmeAdminDialog(
        context: context,
        step: step,
        steps: steps,
        setNewDocs: (docs) {
          setDocs(docs);
        }),
    (step, steps) async => await areYouSureAdminDialog(
          context: context,
          step: step,
          steps: steps,
          getApiHeaders: getApiHeaders,
          getBaseUrl: getBaseUrl,
          getApiName: getApiName,
          getEarningRate: getEarningRate,
          getEarningType: getEarningType,
          getDocs: getDocs,
        )
  ];
  int step = 0;
  while (step < journey.length && step >= 0) {
    DialogDirection? direction = await journey[step](step + 1, journey.length);
    if (direction == null) {
      return false;
    } else if (direction == DialogDirection.next) {
      step = step + 1;
    } else if (direction == DialogDirection.back) {
      step = step - 1;
    } else if (direction == DialogDirection.cancel) {
      return false;
    }
  }
  if (step >= journey.length) {
    return true;
  } else {
    return false;
  }
}

Future<void> showOnUpdatedDialog({
  required BuildContext context,
  required List<dynamic> successfulUpdateKeys,
  required List<dynamic> failedUpdateKeys,
}) async {
  // Show the dialog first
  showDialog(
    context: context,
    barrierDismissible:
        false, // Prevents closing the dialog by tapping outside of it
    builder: (BuildContext context) {
      return AlertDialog(
        actions: [
          PointerInterceptor(
              child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) {
                      // Here, we assume that a Dialog doesn't have a route name (which is true by default).
                      // If you've given a custom name to your Dialog route, check against that name instead.
                      return route.settings.name != null;
                    });
                  },
                  child: const Text("OK")))
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (failedUpdateKeys.isNotEmpty)
              Text(
                "The following updates were successful:",
                style:
                    TextStyle(fontSize: isDesktopResolution(context) ? 18 : 14),
                textAlign: TextAlign.start,
                softWrap: true,
              ),
            if (failedUpdateKeys.isNotEmpty)
              const SizedBox(
                height: 10,
              ),
            if (failedUpdateKeys.isNotEmpty)
              Text(jsonEncode(successfulUpdateKeys)),
            const SizedBox(
              height: 25,
            ),
            if (failedUpdateKeys.isNotEmpty)
              Text(
                "The following updates failed:",
                style:
                    TextStyle(fontSize: isDesktopResolution(context) ? 18 : 14),
                textAlign: TextAlign.start,
                softWrap: true,
              ),
            if (failedUpdateKeys.isNotEmpty)
              Text(jsonEncode(failedUpdateKeys))
            else if (failedUpdateKeys.isEmpty)
              Text(
                "Your updates were successful",
                style:
                    TextStyle(fontSize: isDesktopResolution(context) ? 18 : 14),
                textAlign: TextAlign.start,
                softWrap: true,
              )
          ],
        ),
      );
    },
  );
}

enum RetrySelected { yes, no }

Future<bool?> showWaitingOnFutureDialog(
    {required BuildContext context,
    required Future<dynamic> future,
    bool isRetryable = false}) async {
  // If isRetryable is set to true, the returned future<bool?> indicates whether
  // the user wanted to retry the operation or not. In all scenarios, if the
  // returned value is null, the argument "future" resolved before the user
  // clicked "yes" or "no" to retry.

  // Show the dialog first
  Future<RetrySelected?> retrySelectedFuture = showDialog<RetrySelected?>(
    context: context,
    barrierDismissible:
        true, // Prevents closing the dialog by tapping outside of it
    builder: (BuildContext context) {
      return AlertDialog(
        content: PointerInterceptor(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                key: Key("showWaitingOnFutureDialogSpinner")),
            const SizedBox(height: 20),
            const Text("Please wait..."),
            if (isRetryable) const SizedBox(height: 20),
            if (isRetryable)
              FutureBuilder<bool>(
                  future:
                      Future.delayed(const Duration(seconds: 10), () => true),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          "This is taking a while.\nWould you like to retry?"),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, RetrySelected.no),
                            child: const Text("No")),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, RetrySelected.yes),
                            child: const Text("Yes"))
                      ])
                    ]);
                  })
          ],
        )),
      );
    },
  );

  var anyFuture = Future.any([future, retrySelectedFuture]);

  // Await the future
  var anyResult = await anyFuture.catchError((error) {
    // Handle any errors if necessary
    print("Future completed with error: $error");
  }).whenComplete(() {
    // Ensure to close the dialog when the future completes or encounters an error

    Navigator.of(context).popUntil((route) {
      // Here, we assume that a Dialog doesn't have a route name (which is true by default).
      // If you've given a custom name to your Dialog route, check against that name instead.
      return route.settings.name != null;
    });
  });
  if (anyResult == RetrySelected.yes) {
    return true;
  } else if (anyResult == RetrySelected.no) {
    return false;
  } else {
    return null;
  }
}

Future<DialogDirection?> areYouSureAdminDialog({
  required BuildContext context,
  required Map<String, String> Function() getApiHeaders,
  required String Function() getBaseUrl,
  required String Function() getApiName,
  required double Function() getEarningRate,
  required ChargingChoice Function() getEarningType,
  required AssetModel? Function() getDocs,
  required int step,
  required int steps,
}) async {
  // Show the dialog first
  return showDialog<DialogDirection>(
    context: context,
    barrierDismissible:
        false, // Prevents closing the dialog by tapping outside of it
    builder: (BuildContext context) {
      return AlertDialog(
          actions: [
            TextButton(
                key: const Key("AreYouSureNo"),
                onPressed: () {
                  Navigator.pop(context, DialogDirection.cancel);
                },
                child: const Text("No")),
            TextButton(
                key: const Key("AreYouSureYes"),
                onPressed: () {
                  Navigator.pop(context, DialogDirection.next);
                },
                child: const Text("Yes"))
          ],
          content: getDialogTemplate(
            context: context,
            step: step,
            steps: steps,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Would you like to continue?",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktopResolution(context) ? 18 : 14),
                  textAlign: TextAlign.start,
                  softWrap: true,
                ),
                const SizedBox(
                  height: 25,
                ),
                Text(
                  "You are about to update the following:",
                  style: TextStyle(
                      fontSize: isDesktopResolution(context) ? 18 : 14),
                  textAlign: TextAlign.start,
                  softWrap: true,
                ),
                const SizedBox(
                  height: 25,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bulletPointItem(
                                context, "API name: ${getApiName()}"),
                            bulletPointItem(
                                context, "Base URL: ${getBaseUrl()}"),
                            bulletPointItem(
                                context, "Headers: ${getApiHeaders()}"),
                            bulletPointItem(context,
                                "Earnings: ${getEarningRate()} XRP ${getEarningType().name}"),
                            if (getDocs() != null)
                              bulletPointItem(
                                  context, "Docs: ${getDocs()!.fileName}"),
                          ],
                        ))
                  ],
                )
              ],
            ),
          ));
    },
  );
}

Future<bool?> showRetryDialog(
    {required BuildContext context, required String text}) async {
  // Show the dialog first
  return showDialog<bool>(
    context: context,
    barrierDismissible:
        false, // Prevents closing the dialog by tapping outside of it
    builder: (BuildContext context) {
      return AlertDialog(
        actions: [
          TextButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop(false);
              }),
          TextButton(
              child: const Text("Yes"),
              onPressed: () {
                Navigator.of(context).pop(true);
              })
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              softWrap: true,
            )
          ],
        ),
      );
    },
  );
}

Future<void> showErrorDialog(
    {required BuildContext context, required String text}) async {
  // Show the dialog first
  showDialog(
    context: context,
    barrierDismissible:
        false, // Prevents closing the dialog by tapping outside of it
    builder: (BuildContext context) {
      return AlertDialog(
        actions: [
          TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).popUntil((route) {
                  // Here, we assume that a Dialog doesn't have a route name (which is true by default).
                  // If you've given a custom name to your Dialog route, check against that name instead.
                  return route.settings.name != null;
                });
              })
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              softWrap: true,
            )
          ],
        ),
      );
    },
  );
}

Future<DialogDirection?> showAssetNameAdminDialog(
    {required BuildContext context,
    required String currentAssetName,
    required int step,
    required int steps,
    required void Function(String name) setNewAssetName}) async {
  return await showDialog<DialogDirection>(
      context: context,
      builder: (BuildContext _) {
        return getDialog(
          context,
          child: AssetNameWidget(
              defaultName: currentAssetName,
              step: step,
              steps: steps,
              onDroppedFile: ((file) {}),
              onNextClicked: (name, choice) {
                setNewAssetName(name);
                Navigator.pop(context, DialogDirection.next);
              }),
        );
      });
}

Future<DialogDirection?> showEarningsAdminDialog(
    {required BuildContext context,
    required double currentEarningsRate,
    required ChargingChoice currentChargingChoice,
    required int step,
    required int steps,
    required void Function(double earningRate, ChargingChoice chargingChoice)
        setNewChargingStrategy}) async {
  return await showDialog<DialogDirection>(
    context: context,
    builder: (BuildContext context) {
      return getDialog(context,
          child: ChargeWidget(
              step: step,
              steps: steps,
              defaultChargingRate: currentEarningsRate,
              defaultChargingChoice: currentChargingChoice,
              onNextClicked: (assetEarnings, earningChoice) {
                setNewChargingStrategy(assetEarnings, earningChoice);
                Navigator.pop(context, DialogDirection.next);
              }));
    },
  );
}

Future<DialogDirection?> showCredentialsAdminDialog(
    {required BuildContext context,
    required String currentBaseUrl,
    required Map<String, String> currentHeaders,
    required int step,
    required int steps,
    required void Function(String baseUrl, Map<String, String> headers)
        setNewCredentials}) async {
  return await showDialog<DialogDirection>(
      context: context,
      builder: (BuildContext context) {
        return getDialog(context,
            child: LinkedAPIDetailsWidget(
              step: step,
              steps: steps,
              defaultHeaders: currentHeaders,
              defaultUrl: currentBaseUrl,
              onNextClicked: (apiUrl, apiKeys) {
                setNewCredentials(apiUrl, apiKeys);
                Navigator.pop(context, DialogDirection.next);
              },
            ));
      });
}

Future<DialogDirection?> showReadmeAdminDialog(
    {required BuildContext context,
    required int step,
    required int steps,
    required void Function(AssetModel? docs) setNewDocs}) async {
  return await showDialog<DialogDirection>(
      context: context,
      builder: (BuildContext context) {
        return getDialog(context,
            child: DocsAdminUpdateWidget(
                step: step,
                steps: steps,
                onDroppedFile: ((file) {}),
                onNextClicked: (readme) async {
                  setNewDocs(readme);
                  Navigator.pop(context, DialogDirection.next);
                },
                onSkipClicked: () {
                  setNewDocs(null);
                  Navigator.pop(context, DialogDirection.next);
                }));
      });
}

class DocsAdminUpdateWidget extends StatefulWidget {
  final ValueChanged<AssetModel> onDroppedFile;
  final Function(AssetModel) onNextClicked;
  final Function()? onSkipClicked;
  final int step;
  final int steps;

  const DocsAdminUpdateWidget({
    super.key,
    required this.onDroppedFile,
    required this.onNextClicked,
    this.onSkipClicked,
    required this.step,
    required this.steps,
  });
  @override
  _DocsAdminUpdateWidgetState createState() => _DocsAdminUpdateWidgetState();
}

class _DocsAdminUpdateWidgetState extends State<DocsAdminUpdateWidget> {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      file != null
                          ? "Selected README/OpenAPI json: ${file!.fileName}"
                          : "No README/OpenAPI json selected",
                      style: TextStyle(
                          fontSize: isDesktopResolution(context) ? 25 : 12),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    IconButton(
                      onPressed: () async {
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
                          Navigator.of(context).pop(DialogDirection.back);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          size: isDesktopResolution(context) ? 25 : 12,
                        ),
                        label: Text(
                          key: const Key("UpdateDocsBack"),
                          "Back",
                          style: TextStyle(
                              fontSize: isDesktopResolution(context) ? 25 : 12),
                        )),
                    const SizedBox(
                      width: 16,
                    ),
                    getFileUploadButton(
                        const Key("choose_docs_update_button"),
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
                        key: const Key("update_docs_button"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        onPressed: file != null
                            ? () async {
                                await widget.onNextClicked(file!);
                              }
                            : null,
                        icon: Icon(
                          color: Theme.of(context).colorScheme.onPrimary,
                          Icons.navigate_next_outlined,
                          size: isDesktopResolution(context) ? 25 : 12,
                        ),
                        label: Text(
                          key: const Key("ReadmeDocsNext"),
                          "Next",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: isDesktopResolution(context) ? 25 : 12),
                        )),
                    const SizedBox(
                      width: 16,
                    ),
                    if (widget.onSkipClicked != null)
                      ElevatedButton.icon(
                          key: const Key("skip_docs_button"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4))),
                          onPressed: widget.onSkipClicked == null
                              ? null
                              : () async {
                                  widget.onSkipClicked!();
                                },
                          icon: Icon(
                            color: Theme.of(context).colorScheme.onPrimary,
                            Icons.navigate_next_outlined,
                            size: isDesktopResolution(context) ? 25 : 12,
                          ),
                          label: Text(
                            key: const Key("ReadmeDocsSkip"),
                            "Skip",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize:
                                    isDesktopResolution(context) ? 25 : 12),
                          ))
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
