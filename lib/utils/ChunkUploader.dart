import 'dart:async';
import 'dart:convert';
import "package:universal_html/html.dart";
import 'dart:math';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/src/media_type.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:logger/logger.dart';
import 'package:wakelock/wakelock.dart';

import '../wallet/xrpl_wallet.dart';

class UploadRequest {
  final http.BaseRequest Function(String path)
      getMintingRequest; // We use a getter here because a BaseRequest.send()
  // can only be made once per instance. Because BaseRequest is in a for
  // loop below, its send() method would be called multiple
  final AssetModel model;
  final String payment;
  final Function(double) progressStatus;
  late final int _maxChunkSize;
  late DropzoneViewController controller;
  final XRPLWallet? Function() getWallet;
  bool _cancel = false;
  bool _complete = false;

  UploadRequest({
    required this.payment,
    required this.getMintingRequest,
    required this.model,
    required this.progressStatus,
    required this.getWallet,
    int maxChunkSize = 1024 * 1024 * 10,
  }) {
    _maxChunkSize = min(model.size, maxChunkSize);
  }

  Future<BaseResponse?> upload(String path) async {
    Wakelock.enable();
    var logger = Logger();
    StreamedResponse? finalResponse;
    int i = 0;
    int maxNumberOfRetries = 10;
    int retries = 0;
    while (i < _chunksCount) {
      try {
        if (_cancel) {
          _cancel = false;
          return Response("{'info': 'Client request cancelled'}", 400);
        }
        final start = _getChunkStart(i);
        final end = _getChunkEnd(i);
        final chunkStream = _getChunkStream(start, end);

        var request = getMintingRequest(path);

        logger.d("Preparing header");
        Map<String, String> header = {
          "Asset-Length": "${end - start}",
          "Asset-Range": "bytes $start-${end - 1}/${model.size}",
          "Payment-Claim": payment // TODO : This header argument will
          // likely be derived from the client wallet
        };
        request.headers.addAll(header);

        logger.d("Preparing fields in body");
        Map<String, String> fields = {
          "assetName": model.modelName,
          "chainID": "xrpl", // TODO : Add user input for this
          "walletID": getWallet()!.address,
          "labels": ""
        };

        if (request.runtimeType == http.MultipartRequest) {
          (request as http.MultipartRequest).fields.addAll(fields);
          logger.d("Preparing file in body");
          request.files.add(http.MultipartFile(
              contentType: MediaType('multipart', 'form-data'),
              "modelChunk",
              chunkStream,
              end - start,
              filename: model.fileName));
        }

        logger.d("Sending request");
        finalResponse = await request.send();
        logger.d("Sent request");

        var responseString = await finalResponse.stream.bytesToString();
        logger.d("Response: $responseString");
        if (finalResponse.statusCode != 200 &&
            finalResponse.statusCode != 308) {
          return StreamedResponse(Stream.empty(), finalResponse.statusCode,
              reasonPhrase: finalResponse.reasonPhrase);
        }
        // TODO : Deal with response appropriately

        _updateProgress(i + 1);
        i = i + 1;
      } catch (e) {
        retries += 1;
        if (retries >= maxNumberOfRetries) {
          throw http.ClientException(
              "Chunk $i failed to upload after $retries retries: ${e.toString()}");
        }
        logger.d("Chunk $i was interupted: ${e.toString()}. Retry $retries.");
      }
    }
    _complete = true;
    Wakelock.disable();
    return finalResponse;
  }

  // Returning end byte offset of current chunk
  void cancelUpload() => _cancel = true;

  Stream<List<int>> _getChunkStream(int start, int end) async* {
    final reader = FileReader();
    final blob = model.imageFile.slice(start, end);
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;
    yield reader.result as List<int>;
  }

  // Updating total upload progress
  void _updateProgress(int chunkIndex) {
    double totalUploadedSize = chunkIndex * _maxChunkSize as double;
    double totalUploadProgress = min(totalUploadedSize / model.size, 1.0);
    progressStatus(totalUploadProgress);
    // Fail-safe assurance that 'progressStatus' reaches 1 eventually:
    if (_complete) {
      progressStatus(1);
    }
  }

  // Returning start byte offset of current chunk
  int _getChunkStart(int chunkIndex) => chunkIndex * _maxChunkSize;

  // Returning end byte offset of current chunk
  int _getChunkEnd(int chunkIndex) =>
      min((chunkIndex + 1) * _maxChunkSize, model.size);

  // Returning chunks count based on file size and maximum chunk size
  int get _chunksCount {
    var result = (model.size / _maxChunkSize).ceil();
    return result;
  }
}
