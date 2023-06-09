import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/config.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:dhali/utils/Uploaders.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:universal_io/io.dart';
import 'dart:html' as html;
import 'dart:convert';

import 'package:uuid/uuid.dart';

Widget consumerJourney(
    {required BuildContext context,
    required MarketplaceListData assetDescriptor,
    required String runURL,
    required DhaliWallet? Function() getWallet,
    required FirebaseFirestore? Function() getFirestore,
    required BaseRequest Function(String method, String path) getRequest}) {
  if (getWallet() == null) {
    return const AlertDialog(
      title: Text("Unable to proceed"),
      content: Text("Please link a wallet using the Wallet page"),
    );
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
        file: input,
        inferenceCost:
            assetDescriptor.pricePerRun, // TODO : Get this number dynamically
        yesClicked: ((asset, earningsInferenceCost) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return run(
                    context: context,
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
    required AssetModel input,
    required String runURL,
    required DhaliWallet? Function() getWallet,
    required FirebaseFirestore? Function() getFirestore,
    required BaseRequest Function(String method, String path) getRequest}) {
  String dest = Config.config!["DHALI_PUBLIC_ADDRESS"];

  var runUrlSplit = runURL.split("/");
  String assetUuid = runUrlSplit[runUrlSplit.length - 2];

  var payment = getFirestore()!
      .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
      .doc(assetUuid)
      .get()
      .then((value) async {
    if (value.exists) {
      double cost = (value.data()![Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                  ["EXPECTED_INFERENCE_COST_PER_MS"]] *
              1.4)
          .ceil(); // TODO : Ensure this
      // factor is effectively
      // dealt with

      var channelDescriptors =
          await getWallet()!.getOpenPaymentChannels(destination_address: dest);

      double to_claim = 0;
      if (channelDescriptors.isEmpty) {
        channelDescriptors = [
          await getWallet()!.openPaymentChannel(dest, cost.toString())
        ];
      }
      var doc_id =
          Uuid().v5(Uuid.NAMESPACE_URL, channelDescriptors[0].channelId);
      var to_claim_doc = await getFirestore()!
          .collection("public_claim_info")
          .doc(doc_id)
          .get();
      to_claim =
          to_claim_doc.exists ? to_claim_doc.data()!["to_claim"] as double : 0;
      String total =
          (to_claim + double.parse(cost.toString())).ceil().toString();
      return getWallet()!.preparePayment(
          destinationAddress: dest,
          authAmount: total,
          channelDescriptor: channelDescriptors[0]);
    } else {
      throw HttpException("Asset could not be found");
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
                getOnSuccessWidget: (context, response) => response != null
                    ? DownloadFileWidget(
                        key: Key("download_file"), response: response)
                    : null);
          }
          return Container();
        },
        future: payment,
      ));
}

class DownloadFileWidget extends StatefulWidget {
  const DownloadFileWidget({super.key, required this.response});
  final BaseResponse response;

  @override
  State<DownloadFileWidget> createState() => _DownloadFileWidgetState();
}

class _DownloadFileWidgetState extends State<DownloadFileWidget> {
  List<int>? bytes;
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
            child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                backgroundColor: AppTheme.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))),
            onPressed: () async {
              try {
                bytes = await (widget.response as StreamedResponse)
                    .stream
                    .toBytes();
              } catch (e) {
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
            icon: const Icon(
              Icons.download,
              size: 32,
            ),
            label: const Text(
              "Download result",
              style: TextStyle(fontSize: 30),
            )),
        const SizedBox(
          width: 16,
        ),
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                backgroundColor: AppTheme.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))),
            onPressed: () async {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.exit_to_app,
              size: 32,
            ),
            label: const Text(
              "Exit",
              style: TextStyle(fontSize: 30),
            ))
      ],
    )));
  }
}
