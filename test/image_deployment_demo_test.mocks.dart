// Mocks generated by Mockito 5.4.4 from annotations
// in dhali/test/image_deployment_demo_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i10;
import 'dart:convert' as _i2;
import 'dart:typed_data' as _i8;

import 'package:cloud_firestore/cloud_firestore.dart' as _i5;
import 'package:dhali_wallet/wallet_types.dart' as _i7;
import 'package:dhali_wallet/xrpl_wallet.dart' as _i11;
import 'package:flutter/material.dart' as _i6;
import 'package:http/http.dart' as _i4;
import 'package:http/src/byte_stream.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i9;
import 'package:xrpl/xrpl.dart' as _i12;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeEncoding_0 extends _i1.SmartFake implements _i2.Encoding {
  _FakeEncoding_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeUri_1 extends _i1.SmartFake implements Uri {
  _FakeUri_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeByteStream_2 extends _i1.SmartFake implements _i3.ByteStream {
  _FakeByteStream_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStreamedResponse_3 extends _i1.SmartFake
    implements _i4.StreamedResponse {
  _FakeStreamedResponse_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFirebaseFirestore_4 extends _i1.SmartFake
    implements _i5.FirebaseFirestore {
  _FakeFirebaseFirestore_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeValueNotifier_5<T> extends _i1.SmartFake
    implements _i6.ValueNotifier<T> {
  _FakeValueNotifier_5(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePaymentChannelDescriptor_6 extends _i1.SmartFake
    implements _i7.PaymentChannelDescriptor {
  _FakePaymentChannelDescriptor_6(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [Request].
///
/// See the documentation for Mockito's code generation for more information.
class MockRequest extends _i1.Mock implements _i4.Request {
  MockRequest() {
    _i1.throwOnMissingStub(this);
  }

  @override
  int get contentLength => (super.noSuchMethod(
        Invocation.getter(#contentLength),
        returnValue: 0,
      ) as int);

  @override
  set contentLength(int? value) => super.noSuchMethod(
        Invocation.setter(
          #contentLength,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.Encoding get encoding => (super.noSuchMethod(
        Invocation.getter(#encoding),
        returnValue: _FakeEncoding_0(
          this,
          Invocation.getter(#encoding),
        ),
      ) as _i2.Encoding);

  @override
  set encoding(_i2.Encoding? value) => super.noSuchMethod(
        Invocation.setter(
          #encoding,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i8.Uint8List get bodyBytes => (super.noSuchMethod(
        Invocation.getter(#bodyBytes),
        returnValue: _i8.Uint8List(0),
      ) as _i8.Uint8List);

  @override
  set bodyBytes(List<int>? value) => super.noSuchMethod(
        Invocation.setter(
          #bodyBytes,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  String get body => (super.noSuchMethod(
        Invocation.getter(#body),
        returnValue: _i9.dummyValue<String>(
          this,
          Invocation.getter(#body),
        ),
      ) as String);

  @override
  set body(String? value) => super.noSuchMethod(
        Invocation.setter(
          #body,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  Map<String, String> get bodyFields => (super.noSuchMethod(
        Invocation.getter(#bodyFields),
        returnValue: <String, String>{},
      ) as Map<String, String>);

  @override
  set bodyFields(Map<String, String>? fields) => super.noSuchMethod(
        Invocation.setter(
          #bodyFields,
          fields,
        ),
        returnValueForMissingStub: null,
      );

  @override
  String get method => (super.noSuchMethod(
        Invocation.getter(#method),
        returnValue: _i9.dummyValue<String>(
          this,
          Invocation.getter(#method),
        ),
      ) as String);

  @override
  Uri get url => (super.noSuchMethod(
        Invocation.getter(#url),
        returnValue: _FakeUri_1(
          this,
          Invocation.getter(#url),
        ),
      ) as Uri);

  @override
  Map<String, String> get headers => (super.noSuchMethod(
        Invocation.getter(#headers),
        returnValue: <String, String>{},
      ) as Map<String, String>);

  @override
  bool get persistentConnection => (super.noSuchMethod(
        Invocation.getter(#persistentConnection),
        returnValue: false,
      ) as bool);

  @override
  set persistentConnection(bool? value) => super.noSuchMethod(
        Invocation.setter(
          #persistentConnection,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool get followRedirects => (super.noSuchMethod(
        Invocation.getter(#followRedirects),
        returnValue: false,
      ) as bool);

  @override
  set followRedirects(bool? value) => super.noSuchMethod(
        Invocation.setter(
          #followRedirects,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  int get maxRedirects => (super.noSuchMethod(
        Invocation.getter(#maxRedirects),
        returnValue: 0,
      ) as int);

  @override
  set maxRedirects(int? value) => super.noSuchMethod(
        Invocation.setter(
          #maxRedirects,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool get finalized => (super.noSuchMethod(
        Invocation.getter(#finalized),
        returnValue: false,
      ) as bool);

  @override
  _i3.ByteStream finalize() => (super.noSuchMethod(
        Invocation.method(
          #finalize,
          [],
        ),
        returnValue: _FakeByteStream_2(
          this,
          Invocation.method(
            #finalize,
            [],
          ),
        ),
      ) as _i3.ByteStream);

  @override
  _i10.Future<_i4.StreamedResponse> send() => (super.noSuchMethod(
        Invocation.method(
          #send,
          [],
        ),
        returnValue:
            _i10.Future<_i4.StreamedResponse>.value(_FakeStreamedResponse_3(
          this,
          Invocation.method(
            #send,
            [],
          ),
        )),
      ) as _i10.Future<_i4.StreamedResponse>);
}

/// A class which mocks [MultipartRequest].
///
/// See the documentation for Mockito's code generation for more information.
class MockMultipartRequest extends _i1.Mock implements _i4.MultipartRequest {
  MockMultipartRequest() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Map<String, String> get fields => (super.noSuchMethod(
        Invocation.getter(#fields),
        returnValue: <String, String>{},
      ) as Map<String, String>);

  @override
  List<_i4.MultipartFile> get files => (super.noSuchMethod(
        Invocation.getter(#files),
        returnValue: <_i4.MultipartFile>[],
      ) as List<_i4.MultipartFile>);

  @override
  int get contentLength => (super.noSuchMethod(
        Invocation.getter(#contentLength),
        returnValue: 0,
      ) as int);

  @override
  set contentLength(int? value) => super.noSuchMethod(
        Invocation.setter(
          #contentLength,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  String get method => (super.noSuchMethod(
        Invocation.getter(#method),
        returnValue: _i9.dummyValue<String>(
          this,
          Invocation.getter(#method),
        ),
      ) as String);

  @override
  Uri get url => (super.noSuchMethod(
        Invocation.getter(#url),
        returnValue: _FakeUri_1(
          this,
          Invocation.getter(#url),
        ),
      ) as Uri);

  @override
  Map<String, String> get headers => (super.noSuchMethod(
        Invocation.getter(#headers),
        returnValue: <String, String>{},
      ) as Map<String, String>);

  @override
  bool get persistentConnection => (super.noSuchMethod(
        Invocation.getter(#persistentConnection),
        returnValue: false,
      ) as bool);

  @override
  set persistentConnection(bool? value) => super.noSuchMethod(
        Invocation.setter(
          #persistentConnection,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool get followRedirects => (super.noSuchMethod(
        Invocation.getter(#followRedirects),
        returnValue: false,
      ) as bool);

  @override
  set followRedirects(bool? value) => super.noSuchMethod(
        Invocation.setter(
          #followRedirects,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  int get maxRedirects => (super.noSuchMethod(
        Invocation.getter(#maxRedirects),
        returnValue: 0,
      ) as int);

  @override
  set maxRedirects(int? value) => super.noSuchMethod(
        Invocation.setter(
          #maxRedirects,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool get finalized => (super.noSuchMethod(
        Invocation.getter(#finalized),
        returnValue: false,
      ) as bool);

  @override
  _i3.ByteStream finalize() => (super.noSuchMethod(
        Invocation.method(
          #finalize,
          [],
        ),
        returnValue: _FakeByteStream_2(
          this,
          Invocation.method(
            #finalize,
            [],
          ),
        ),
      ) as _i3.ByteStream);

  @override
  _i10.Future<_i4.StreamedResponse> send() => (super.noSuchMethod(
        Invocation.method(
          #send,
          [],
        ),
        returnValue:
            _i10.Future<_i4.StreamedResponse>.value(_FakeStreamedResponse_3(
          this,
          Invocation.method(
            #send,
            [],
          ),
        )),
      ) as _i10.Future<_i4.StreamedResponse>);
}

/// A class which mocks [XRPLWallet].
///
/// See the documentation for Mockito's code generation for more information.
class MockXRPLWallet extends _i1.Mock implements _i11.XRPLWallet {
  MockXRPLWallet() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.FirebaseFirestore Function() get getFirestore => (super.noSuchMethod(
        Invocation.getter(#getFirestore),
        returnValue: () => _FakeFirebaseFirestore_4(
          this,
          Invocation.getter(#getFirestore),
        ),
      ) as _i5.FirebaseFirestore Function());

  @override
  set mnemonic(String? _mnemonic) => super.noSuchMethod(
        Invocation.setter(
          #mnemonic,
          _mnemonic,
        ),
        returnValueForMissingStub: null,
      );

  @override
  String get address => (super.noSuchMethod(
        Invocation.getter(#address),
        returnValue: _i9.dummyValue<String>(
          this,
          Invocation.getter(#address),
        ),
      ) as String);

  @override
  _i6.ValueNotifier<String?> get balance => (super.noSuchMethod(
        Invocation.getter(#balance),
        returnValue: _FakeValueNotifier_5<String?>(
          this,
          Invocation.getter(#balance),
        ),
      ) as _i6.ValueNotifier<String?>);

  @override
  _i6.ValueNotifier<String?> get amount => (super.noSuchMethod(
        Invocation.getter(#amount),
        returnValue: _FakeValueNotifier_5<String?>(
          this,
          Invocation.getter(#amount),
        ),
      ) as _i6.ValueNotifier<String?>);

  @override
  _i10.Future<void> updateBalance() => (super.noSuchMethod(
        Invocation.method(
          #updateBalance,
          [],
        ),
        returnValue: _i10.Future<void>.value(),
        returnValueForMissingStub: _i10.Future<void>.value(),
      ) as _i10.Future<void>);

  @override
  String publicKey() => (super.noSuchMethod(
        Invocation.method(
          #publicKey,
          [],
        ),
        returnValue: _i9.dummyValue<String>(
          this,
          Invocation.method(
            #publicKey,
            [],
          ),
        ),
      ) as String);

  @override
  _i10.Future<Map<String, String>> preparePayment({
    required String? destinationAddress,
    required String? authAmount,
    required _i7.PaymentChannelDescriptor? channelDescriptor,
    required _i6.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #preparePayment,
          [],
          {
            #destinationAddress: destinationAddress,
            #authAmount: authAmount,
            #channelDescriptor: channelDescriptor,
            #context: context,
          },
        ),
        returnValue: _i10.Future<Map<String, String>>.value(<String, String>{}),
      ) as _i10.Future<Map<String, String>>);

  @override
  String sendDrops(
    String? amount,
    String? channelId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendDrops,
          [
            amount,
            channelId,
          ],
        ),
        returnValue: _i9.dummyValue<String>(
          this,
          Invocation.method(
            #sendDrops,
            [
              amount,
              channelId,
            ],
          ),
        ),
      ) as String);

  @override
  _i10.Future<dynamic> submitRequest(
    _i12.BaseRequest? request,
    _i12.Client? client,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #submitRequest,
          [
            request,
            client,
          ],
        ),
        returnValue: _i10.Future<dynamic>.value(),
      ) as _i10.Future<dynamic>);

  @override
  _i10.Future<dynamic> getAvailableNFTs() => (super.noSuchMethod(
        Invocation.method(
          #getAvailableNFTs,
          [],
        ),
        returnValue: _i10.Future<dynamic>.value(),
      ) as _i10.Future<dynamic>);

  @override
  _i10.Future<bool> acceptOffer(
    String? offerIndex, {
    required _i6.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #acceptOffer,
          [offerIndex],
          {#context: context},
        ),
        returnValue: _i10.Future<bool>.value(false),
      ) as _i10.Future<bool>);

  @override
  _i10.Future<List<_i7.NFTOffer>> getNFTOffers(String? nfTokenId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getNFTOffers,
          [nfTokenId],
        ),
        returnValue: _i10.Future<List<_i7.NFTOffer>>.value(<_i7.NFTOffer>[]),
      ) as _i10.Future<List<_i7.NFTOffer>>);

  @override
  _i10.Future<List<_i7.PaymentChannelDescriptor>> getOpenPaymentChannels(
          {String? destination_address}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getOpenPaymentChannels,
          [],
          {#destination_address: destination_address},
        ),
        returnValue: _i10.Future<List<_i7.PaymentChannelDescriptor>>.value(
            <_i7.PaymentChannelDescriptor>[]),
      ) as _i10.Future<List<_i7.PaymentChannelDescriptor>>);

  @override
  _i10.Future<_i7.PaymentChannelDescriptor> openPaymentChannel(
    String? destinationAddress,
    String? amount, {
    required _i6.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #openPaymentChannel,
          [
            destinationAddress,
            amount,
          ],
          {#context: context},
        ),
        returnValue: _i10.Future<_i7.PaymentChannelDescriptor>.value(
            _FakePaymentChannelDescriptor_6(
          this,
          Invocation.method(
            #openPaymentChannel,
            [
              destinationAddress,
              amount,
            ],
            {#context: context},
          ),
        )),
      ) as _i10.Future<_i7.PaymentChannelDescriptor>);

  @override
  _i10.Future<bool> fundPaymentChannel(
    _i7.PaymentChannelDescriptor? descriptor,
    String? amount, {
    required _i6.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #fundPaymentChannel,
          [
            descriptor,
            amount,
          ],
          {#context: context},
        ),
        returnValue: _i10.Future<bool>.value(false),
      ) as _i10.Future<bool>);
}
