import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import 'package:dhali/analytics/analytics.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/config.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:dhali/utils/Uploaders.dart';
import 'package:dhali/utils/display_utils.dart';
import 'package:dhali/utils/row_else_column.dart';
import 'package:dhali_wallet/dhali_wallet.dart';

Widget consumerJourney(
    {required BuildContext context,
    required MarketplaceListData assetDescriptor,
    required String runURL,
    required DhaliWallet? Function() getWallet,
    required FirebaseFirestore? Function() getFirestore,
    required BaseRequest Function(String method, String path) getRequest}) {
  if (getWallet() == null) {
    gtag(
        command: "event",
        target: "RunWalletInactive",
        parameters: {"url": runURL});
    return const AlertDialog(
      title: Text("Unable to proceed"),
      content: Text("Please link a wallet using the Wallet page"),
    );
  }

  if (getFirestore().runtimeType == FirebaseFirestore) {
    // Only hit the Warmup the asset if `firestore` is not a mocked type
    var runUrlSplit = runURL.split("/");
    var warmUrl =
        '${runUrlSplit.sublist(0, runUrlSplit.length - 1).join("/")}/warmup';
    http.get(Uri.parse(warmUrl));
  }

  return Dialog(
    backgroundColor: Colors.transparent,
    child: DropzoneRunWidget(
      onDroppedFile: ((file) {}),
      onNextClicked: (asset) {
        Navigator.of(context).pop();
        showDialog(
            context: context,
            builder: (BuildContext context) => costDialog(
                context: context,
                getFirestore: getFirestore,
                assetDescriptor: assetDescriptor,
                runURL: runURL,
                input: asset,
                getWallet: getWallet,
                getRequest: getRequest));
      },
    ),
  );
}

Dialog costDialog(
    {required BuildContext context,
    required MarketplaceListData assetDescriptor,
    required String runURL,
    required AssetModel input,
    required DhaliWallet? Function() getWallet,
    required FirebaseFirestore? Function() getFirestore,
    required BaseRequest Function(String method, String path) getRequest}) {
  return Dialog(
      backgroundColor: Colors.transparent,
      child: InferenceCostWidget(
        step: 1, steps: 1,
        file: input,
        inferenceCost:
            assetDescriptor.pricePerRun, // TODO : Get this number dynamically
        yesClicked: ((asset, earningsInferenceCost) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return run(
                    context: context,
                    assetDescriptor: assetDescriptor,
                    runURL: runURL,
                    input: input,
                    getFirestore: getFirestore,
                    getWallet: getWallet,
                    getRequest: getRequest);
              });
        }),
      ));
}

Dialog run(
    {required BuildContext context,
    required MarketplaceListData assetDescriptor,
    required AssetModel input,
    required String runURL,
    required DhaliWallet? Function() getWallet,
    required FirebaseFirestore? Function() getFirestore,
    required BaseRequest Function(String method, String path) getRequest}) {
  String dest = Config.config!["DHALI_PUBLIC_ADDRESS"];

  var payment = getFirestore()!
      .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
      .doc(assetDescriptor.assetID)
      .get()
      .then((value) async {
    if (value.exists) {
      double cost = (value.data()![Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                  ["AVERAGE_INFERENCE_TIME_MS"]] *
              Config.config!["DHALI_CPU_INFERENCE_COST_PER_MS"] *
              (1 +
                  (Config.config!["DHALI_EARNINGS_PERCENTAGE_PER_INFERENCE"]
                          as double) /
                      100 +
                  (Config.config!["DHALI_EARNINGS_PERCENTAGE_PER_INFERENCE"]
                          as double) /
                      100) *
              3)
          .ceil(); // TODO : Ensure this
      // factor is effectively
      // dealt with

      var channelDescriptors =
          await getWallet()!.getOpenPaymentChannels(destination_address: dest);

      if (channelDescriptors.isEmpty) {
        channelDescriptors = [
          await getWallet()!.openPaymentChannel(dest, cost.toString())
        ];
      }
      var docId =
          const Uuid().v5(Uuid.NAMESPACE_URL, channelDescriptors[0].channelId);
      var toClaimDoc = await getFirestore()!
          .collection("public_claim_info")
          .doc(docId)
          .get();
      double toClaim = 0;
      toClaim =
          toClaimDoc.exists ? toClaimDoc.data()!["to_claim"] as double : 0;
      String total =
          (toClaim + double.parse(cost.toString())).ceil().toString();
      double requiredInChannel =
          double.parse(total) - channelDescriptors[0].amount + 1;
      if (requiredInChannel > 0) {
        await getWallet()!.fundPaymentChannel(
            channelDescriptors[0], requiredInChannel.toString());
      }
      return getWallet()!.preparePayment(
          destinationAddress: dest,
          authAmount: total,
          channelDescriptor: channelDescriptors[0]);
    } else {
      throw const HttpException("Asset could not be found");
    }
  });

  return Dialog(
      backgroundColor: Colors.transparent,
      child: FutureBuilder<Map<String, String>>(
        builder: (context, snapshot) {
          final exceptionString =
              "The NFTUploadingWidget must have access to ${Config.config!["DHALI_ID"]}";
          if (snapshot.hasData) {
            var entryPointUrlRoot = const String.fromEnvironment(
                'ENTRY_POINT_URL_ROOT',
                defaultValue: '');
            if (entryPointUrlRoot == '') {
              entryPointUrlRoot = Config.config!["ROOT_DEPLOY_URL"];
            }
            Map<String, String> payment = snapshot.data!;
            return DataTransmissionWidget(
                getUploader: (
                    {required payment,
                    required getRequest,
                    required dynamic Function(double) progressStatus,
                    required int maxChunkSize,
                    required AssetModel model}) {
                  return RunUploader(
                      payment: payment,
                      getRequest: getRequest,
                      progressStatus: progressStatus,
                      model: model,
                      maxChunkSize: maxChunkSize,
                      getWallet: getWallet);
                },
                payment: payment,
                getRequest: getRequest,
                data: [DataEndpointPair(data: input, endPoint: runURL)],
                onNextClicked: (asset) {},
                getOnSuccessWidget: (context, response) {
                  if (response != null) {
                    return DownloadFileWidget(
                        key: const Key("download_file"),
                        response: response,
                        runURL: runURL);
                  }
                  return null;
                });
          }
          return Container();
        },
        future: payment,
      ));
}

class DownloadFileWidget extends StatefulWidget {
  const DownloadFileWidget(
      {super.key, required this.response, required this.runURL});
  final BaseResponse response;
  final String runURL;

  @override
  State<DownloadFileWidget> createState() => _DownloadFileWidgetState();
}

class _DownloadFileWidgetState extends State<DownloadFileWidget> {
  List<int>? bytes;
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
            child: RowElseColumn(
      isRow: isDesktopResolution(context),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    vertical: isDesktopResolution(context) ? 20 : 10,
                    horizontal: isDesktopResolution(context) ? 20 : 10),
                backgroundColor: AppTheme.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))),
            onPressed: () async {
              try {
                bytes = await (widget.response as StreamedResponse)
                    .stream
                    .toBytes();
                gtag(
                    command: "event",
                    target: "ResultDownloadSuccessful",
                    parameters: {
                      "url": widget.runURL,
                    });
              } catch (e) {
                gtag(
                    command: "event",
                    target: "ResultDownloadUnsuccessful",
                    parameters: {
                      "url": widget.runURL,
                      "response": widget.response
                    });
                if (bytes == null) {
                  throw "An error occured when trying to download your result: ${e.toString()}";
                }
              }

              final dataUri = 'data:text/plain;base64,${base64.encode(bytes!)}';
              html.document.createElement('a') as html.AnchorElement
                ..href = dataUri
                ..download = 'output.txt'
                ..dispatchEvent(html.Event.eventType('MouseEvent', 'click'));
            },
            icon: Icon(
              Icons.download,
              size: isDesktopResolution(context) ? 32 : 16,
            ),
            label: Text(
              "Download result",
              style:
                  TextStyle(fontSize: isDesktopResolution(context) ? 30 : 15),
            )),
        const SizedBox(
          width: 16,
        ),
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    vertical: isDesktopResolution(context) ? 20 : 10,
                    horizontal: isDesktopResolution(context) ? 20 : 10),
                backgroundColor: AppTheme.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))),
            onPressed: () async {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.exit_to_app,
              size: isDesktopResolution(context) ? 32 : 16,
            ),
            label: Text(
              "Exit",
              style:
                  TextStyle(fontSize: isDesktopResolution(context) ? 30 : 15),
            ))
      ],
    )));
  }
}
