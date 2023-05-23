import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dhali/config.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/widgets.dart';
import "package:universal_html/html.dart";
import 'dart:math';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/src/media_type.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:logger/logger.dart';
import 'package:wakelock/wakelock.dart';

typedef GetUploader = BaseUploader Function({
  required String payment,
  required http.BaseRequest Function(String method, String path)
      getRequest, // This is not related to an HTTP GET request
  required AssetModel model,
  required Function(double) progressStatus,
  required int maxChunkSize,
});

Stream<List<int>> _getChunkStream(AssetModel model, int start, int end) async* {
  final reader = FileReader();
  final blob = model.imageFile.slice(start, end);
  reader.readAsArrayBuffer(blob);
  await reader.onLoad.first;
  yield reader.result as List<int>;
}

// Updating total upload progress
void _updateProgress(AssetModel model, Function(double) progressStatus,
    int maxChunkSize, int chunkIndex, bool complete) {
  double totalUploadedSize = chunkIndex * maxChunkSize as double;
  double totalUploadProgress = min(totalUploadedSize / model.size, 1.0);
  progressStatus(totalUploadProgress);
  // Fail-safe assurance that 'progressStatus' reaches 1 eventually:
  if (complete) {
    progressStatus(1);
  }
}

// Returning start byte offset of current chunk
int _getChunkStart(int maxChunkSize, int chunkIndex) =>
    chunkIndex * maxChunkSize;

// Returning end byte offset of current chunk
int _getChunkEnd(AssetModel model, int maxChunkSize, int chunkIndex) =>
    min((chunkIndex + 1) * maxChunkSize, model.size);

// Returning chunks count based on file size and maximum chunk size
int chunksCount(AssetModel model, int maxChunkSize) {
  var result = (model.size / maxChunkSize).ceil();
  return result;
}

abstract class BaseUploader {
  bool _cancel = false;
  bool _complete = false;
  Future<BaseResponse?> upload(String path, {String? sessionID});
  void cancelUpload() => _cancel = true;
}

class RunUploader extends BaseUploader {
  final http.BaseRequest Function(String method, String path)
      getRequest; // We use a getter here because a BaseRequest.send()
  // can only be made once per instance. Because BaseRequest is in a for
  // loop below, its send() method would be called multiple
  final AssetModel model;
  final String payment;
  final Function(double) progressStatus;
  late final int _maxChunkSize;
  late DropzoneViewController controller;
  final DhaliWallet? Function() getWallet;

  RunUploader({
    required this.payment,
    required this.getRequest,
    required this.model,
    required this.progressStatus,
    required this.getWallet,
    int maxChunkSize = 1024 * 1024 * 10,
  }) {
    _maxChunkSize = min(model.size, maxChunkSize);
  }

  @override
  Future<BaseResponse?> upload(String path, {String? sessionID}) async {
    Wakelock.enable();
    var logger = Logger();
    StreamedResponse? finalResponse;
    int i = 0;
    int maxNumberOfRetries = 10;
    int retries = 0;
    while (i < chunksCount(model, _maxChunkSize)) {
      try {
        if (_cancel) {
          _cancel = false;
          return Response("{'info': 'Client request cancelled'}", 400);
        }
        final start = _getChunkStart(_maxChunkSize, i);
        final end = _getChunkEnd(model, _maxChunkSize, i);
        final chunkStream = _getChunkStream(model, start, end);

        var request = getRequest("PUT", path);

        logger.d("Preparing header");
        Map<String, String> header = {
          "Payment-Claim": payment // TODO : This header argument will
          // likely be derived from the client wallet
        };
        request.headers.addAll(header);

        if (request.runtimeType == http.MultipartRequest) {
          logger.d("Preparing file in body");
          (request as http.MultipartRequest).files.add(http.MultipartFile(
              "input", chunkStream, end - start,
              contentType: MediaType('multipart', 'form-data'),
              filename: model.fileName));
        }

        logger.d("Sending request");
        finalResponse = await request.send();
        logger.d("Sent request");

        if (finalResponse.statusCode != 200 &&
            finalResponse.statusCode != 308) {
          return StreamedResponse(Stream.empty(), finalResponse.statusCode);
        }
        // TODO : Deal with response appropriately

        _updateProgress(model, progressStatus, _maxChunkSize, i + 1, _complete);
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
    _updateProgress(model, progressStatus, _maxChunkSize, i + 1, _complete);
    Wakelock.disable();
    return finalResponse;
  }
}

class DeployUploader extends BaseUploader {
  final http.BaseRequest Function(String method, String path)
      getRequest; // We use a getter here because a BaseRequest.send()
  // can only be made once per instance. Because BaseRequest is in a for
  // loop below, its send() method would be called multiple
  final AssetModel model;
  final String payment;
  final Function(double) progressStatus;
  late final int _maxChunkSize;
  late DropzoneViewController controller;
  final DhaliWallet? Function() getWallet;
  final double assetEarningRate;

  DeployUploader({
    required this.payment,
    required this.getRequest,
    required this.model,
    required this.progressStatus,
    required this.getWallet,
    required this.assetEarningRate,
    int maxChunkSize = 1024 * 1024 * 10,
  }) {
    _maxChunkSize = min(model.size, maxChunkSize);
  }

  @override
  Future<BaseResponse?> upload(String path, {String? sessionID}) async {
    Wakelock.enable();
    var logger = Logger();
    StreamedResponse? finalResponse;
    int i = 0;
    int maxNumberOfRetries = 10;
    int retries = 0;
    while (i < chunksCount(model, _maxChunkSize)) {
      try {
        if (_cancel) {
          _cancel = false;
          return Response("{'info': 'Client request cancelled'}", 400);
        }
        final start = _getChunkStart(_maxChunkSize, i);
        final end = _getChunkEnd(model, _maxChunkSize, i);
        final chunkStream = _getChunkStream(model, start, end);

        var request = getRequest("POST", path);

        logger.d("Preparing header");
        Map<String, String> header = {
          "Asset-Length": "${end - start}",
          "Asset-Range": "bytes $start-${end - 1}/${model.size}",
          "Payment-Claim": payment // TODO : This header argument will
          // likely be derived from the client wallet
        };
        if (sessionID != null) {
          header[Config.config!["DHALI_ID"]] = sessionID;
        }
        request.headers.addAll(header);

        logger.d("Preparing fields in body");
        Map<String, String> fields = {
          "assetName": model.modelName,
          "chainID": "xrpl", // TODO : Add user input for this
          "walletID": getWallet()!.address,
          "labels": "",
          "assetEarningRate": "$assetEarningRate"
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

        if (finalResponse.statusCode != 200 &&
            finalResponse.statusCode != 308) {
          throw Exception(
              "Chunk $i returned status code ${finalResponse.statusCode}: ${finalResponse.reasonPhrase}");
        }
        try {
          sessionID = finalResponse!
              .headers[Config.config!["DHALI_ID"].toString().toLowerCase()];
        } catch (e, stacktrace) {
          throw FormatException(
              "Unexpected response from asset deployment, with error: ${e} "
              "and stacktrace: ${stacktrace}");
        }
        // TODO : Deal with response appropriately

        _updateProgress(model, progressStatus, _maxChunkSize, i + 1, _complete);
        i = i + 1;
      } catch (e) {
        // With this exception handling, the client will indefinitely retry
        // to upload failed chunks, provided the failure was caused by a timeout
        // upstream (i.e., a 504 error)
        // This error handling also operates under the assumption that if the
        // responseCode is 200, then the current attempt to send threw an
        // exception and the previous chunk was successful. Thus the current
        // chunk should be retried because the issue is upstream and Dhali
        // independent
        if (finalResponse != null &&
            (finalResponse.statusCode == 504 ||
                finalResponse.statusCode == 200)) {
          // An upstream timeout occured.Wait a minute and try again
          await Future.delayed(const Duration(seconds: 30));
          logger.d("Chunk $i was interupted: ${e.toString()}. Retrying.");
        } else {
          retries += 1;
          if (retries >= maxNumberOfRetries) {
            // Something went wrong!
            logger.d(finalResponse!.statusCode);
            return StreamedResponse(
                const Stream.empty(), finalResponse.statusCode,
                reasonPhrase: finalResponse.reasonPhrase);
          }
        }
      }
    }
    _complete = true;
    _updateProgress(model, progressStatus, _maxChunkSize, i + 1, _complete);
    Wakelock.disable();
    return finalResponse;
  }
}
