import 'package:dhali/app_theme.dart';
import 'package:dhali/config.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:dhali/utils/Uploaders.dart';
import 'package:dhali/utils/payment.dart';
import 'package:dhali/wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:universal_io/io.dart';
import 'dart:html' as html;
import 'dart:convert';

Widget consumerJourney(
    {required BuildContext context,
    required MarketplaceListData assetDescriptor,
    required String runURL,
    required XRPLWallet? Function() getWallet,
    required BaseRequest Function(String method, String path) getRequest}) {
  if (getWallet() == null) {
    return const AlertDialog(
      title: Text("Unable to proceed"),
      content: Text("Your wallet has not been activated"),
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
    required XRPLWallet? Function() getWallet,
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
    required XRPLWallet? Function() getWallet,
    required BaseRequest Function(String method, String path) getRequest}) {
  String dest = Config.config!["DHALI_PUBLIC_ADDRESS"];
  var openChannelsFut =
      getWallet()!.getOpenPaymentChannels(destination_address: dest);
  String amount =
      "10000000"; // TODO : Make sure that these are appropriate 10 XRP
  String authAmount =
      "3000000"; // TODO : Make sure that these are appropriate 3 XRP

  return Dialog(
      backgroundColor: Colors.transparent,
      child: FutureBuilder<List<PaymentChannelDescriptor>>(
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            dynamic channel;

            snapshot.data!.forEach((returnedChannel) {
              if (returnedChannel.amount >= int.parse(authAmount)) {
                channel = returnedChannel;
              }
            });
            if (channel != null) {
              print("\n\n\n\n\nDataTransmissionWidget 1\n\n\n\n\n");
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
                payment: preparePayment(
                    getWallet: getWallet,
                    destinationAddress: dest,
                    authAmount: authAmount,
                    channelId: channel.channelId),
                getRequest: getRequest,
                data: [DataEndpointPair(data: input, endPoint: runURL)],
                onNextClicked: (asset) {},
                getOnSuccessWidget: (context, response) => response != null
                    ? DownloadFileWidget(
                        key: Key("download_file"), response: response)
                    : null,
              );
            }
            var newChannelsFut = getWallet()!.openPaymentChannel(dest, amount);
            return FutureBuilder<PaymentChannelDescriptor>(
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  print("\n\n\n\n\nDataTransmissionWidget 2\n\n\n\n\n");
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
                    payment: preparePayment(
                        getWallet: getWallet,
                        destinationAddress: dest,
                        authAmount: authAmount,
                        channelId: snapshot.data!.channelId),
                    getRequest: getRequest,
                    data: [DataEndpointPair(data: input, endPoint: runURL)],
                    onNextClicked: (asset) {},
                    getOnSuccessWidget: (context, response) => response != null
                        ? DownloadFileWidget(
                            key: Key("download_file"), response: response)
                        : null,
                  );
                }
                return Container();
              },
              future: newChannelsFut,
            );
          }
          return Container();
        },
        future: openChannelsFut,
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
      child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              backgroundColor: AppTheme.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4))),
          onPressed: () async {
            try {
              bytes =
                  await (widget.response as StreamedResponse).stream.toBytes();
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
          label: Text(
            "Download result",
            style: TextStyle(fontSize: 30),
          )),
    ));
  }
}
