// Mocks generated by Mockito 5.4.4 from annotations
// in dhali/test/api_administration_demo_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i9;

import 'package:async/async.dart' as _i14;
import 'package:cloud_firestore/cloud_firestore.dart' as _i4;
import 'package:dhali_wallet/wallet_types.dart' as _i6;
import 'package:dhali_wallet/xrpl_wallet.dart' as _i12;
import 'package:flutter/material.dart' as _i5;
import 'package:http/http.dart' as _i3;
import 'package:http/src/byte_stream.dart' as _i2;
import 'package:http/src/multipart_file.dart' as _i10;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i11;
import 'package:stream_channel/stream_channel.dart' as _i8;
import 'package:web_socket_channel/src/channel.dart' as _i7;
import 'package:xrpl/xrpl.dart' as _i13;

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

class _FakeUri_0 extends _i1.SmartFake implements Uri {
  _FakeUri_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeByteStream_1 extends _i1.SmartFake implements _i2.ByteStream {
  _FakeByteStream_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStreamedResponse_2 extends _i1.SmartFake
    implements _i3.StreamedResponse {
  _FakeStreamedResponse_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFirebaseFirestore_3 extends _i1.SmartFake
    implements _i4.FirebaseFirestore {
  _FakeFirebaseFirestore_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeValueNotifier_4<T> extends _i1.SmartFake
    implements _i5.ValueNotifier<T> {
  _FakeValueNotifier_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePaymentChannelDescriptor_5 extends _i1.SmartFake
    implements _i6.PaymentChannelDescriptor {
  _FakePaymentChannelDescriptor_5(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeWebSocketSink_6 extends _i1.SmartFake implements _i7.WebSocketSink {
  _FakeWebSocketSink_6(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStreamChannel_7<T> extends _i1.SmartFake
    implements _i8.StreamChannel<T> {
  _FakeStreamChannel_7(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFuture_8<T1> extends _i1.SmartFake implements _i9.Future<T1> {
  _FakeFuture_8(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStreamSubscription_9<T1> extends _i1.SmartFake
    implements _i9.StreamSubscription<T1> {
  _FakeStreamSubscription_9(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [MultipartRequest].
///
/// See the documentation for Mockito's code generation for more information.
class MockMultipartRequest extends _i1.Mock implements _i3.MultipartRequest {
  MockMultipartRequest() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Map<String, String> get fields => (super.noSuchMethod(
        Invocation.getter(#fields),
        returnValue: <String, String>{},
      ) as Map<String, String>);

  @override
  List<_i10.MultipartFile> get files => (super.noSuchMethod(
        Invocation.getter(#files),
        returnValue: <_i10.MultipartFile>[],
      ) as List<_i10.MultipartFile>);

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
        returnValue: _i11.dummyValue<String>(
          this,
          Invocation.getter(#method),
        ),
      ) as String);

  @override
  Uri get url => (super.noSuchMethod(
        Invocation.getter(#url),
        returnValue: _FakeUri_0(
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
  _i2.ByteStream finalize() => (super.noSuchMethod(
        Invocation.method(
          #finalize,
          [],
        ),
        returnValue: _FakeByteStream_1(
          this,
          Invocation.method(
            #finalize,
            [],
          ),
        ),
      ) as _i2.ByteStream);

  @override
  _i9.Future<_i3.StreamedResponse> send() => (super.noSuchMethod(
        Invocation.method(
          #send,
          [],
        ),
        returnValue:
            _i9.Future<_i3.StreamedResponse>.value(_FakeStreamedResponse_2(
          this,
          Invocation.method(
            #send,
            [],
          ),
        )),
      ) as _i9.Future<_i3.StreamedResponse>);
}

/// A class which mocks [XRPLWallet].
///
/// See the documentation for Mockito's code generation for more information.
class MockXRPLWallet extends _i1.Mock implements _i12.XRPLWallet {
  MockXRPLWallet() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.FirebaseFirestore Function() get getFirestore => (super.noSuchMethod(
        Invocation.getter(#getFirestore),
        returnValue: () => _FakeFirebaseFirestore_3(
          this,
          Invocation.getter(#getFirestore),
        ),
      ) as _i4.FirebaseFirestore Function());

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
        returnValue: _i11.dummyValue<String>(
          this,
          Invocation.getter(#address),
        ),
      ) as String);

  @override
  _i5.ValueNotifier<String?> get balance => (super.noSuchMethod(
        Invocation.getter(#balance),
        returnValue: _FakeValueNotifier_4<String?>(
          this,
          Invocation.getter(#balance),
        ),
      ) as _i5.ValueNotifier<String?>);

  @override
  _i9.Future<void> updateBalance() => (super.noSuchMethod(
        Invocation.method(
          #updateBalance,
          [],
        ),
        returnValue: _i9.Future<void>.value(),
        returnValueForMissingStub: _i9.Future<void>.value(),
      ) as _i9.Future<void>);

  @override
  String publicKey() => (super.noSuchMethod(
        Invocation.method(
          #publicKey,
          [],
        ),
        returnValue: _i11.dummyValue<String>(
          this,
          Invocation.method(
            #publicKey,
            [],
          ),
        ),
      ) as String);

  @override
  _i9.Future<Map<String, String>> preparePayment({
    required String? destinationAddress,
    required String? authAmount,
    required _i6.PaymentChannelDescriptor? channelDescriptor,
    required _i5.BuildContext? context,
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
        returnValue: _i9.Future<Map<String, String>>.value(<String, String>{}),
      ) as _i9.Future<Map<String, String>>);

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
        returnValue: _i11.dummyValue<String>(
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
  _i9.Future<dynamic> submitRequest(
    _i13.BaseRequest? request,
    _i13.Client? client,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #submitRequest,
          [
            request,
            client,
          ],
        ),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);

  @override
  _i9.Future<dynamic> getAvailableNFTs() => (super.noSuchMethod(
        Invocation.method(
          #getAvailableNFTs,
          [],
        ),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);

  @override
  _i9.Future<bool> acceptOffer(
    String? offerIndex, {
    required _i5.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #acceptOffer,
          [offerIndex],
          {#context: context},
        ),
        returnValue: _i9.Future<bool>.value(false),
      ) as _i9.Future<bool>);

  @override
  _i9.Future<List<_i6.NFTOffer>> getNFTOffers(String? nfTokenId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getNFTOffers,
          [nfTokenId],
        ),
        returnValue: _i9.Future<List<_i6.NFTOffer>>.value(<_i6.NFTOffer>[]),
      ) as _i9.Future<List<_i6.NFTOffer>>);

  @override
  _i9.Future<List<_i6.PaymentChannelDescriptor>> getOpenPaymentChannels(
          {String? destination_address}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getOpenPaymentChannels,
          [],
          {#destination_address: destination_address},
        ),
        returnValue: _i9.Future<List<_i6.PaymentChannelDescriptor>>.value(
            <_i6.PaymentChannelDescriptor>[]),
      ) as _i9.Future<List<_i6.PaymentChannelDescriptor>>);

  @override
  _i9.Future<_i6.PaymentChannelDescriptor> openPaymentChannel(
    String? destinationAddress,
    String? amount, {
    required _i5.BuildContext? context,
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
        returnValue: _i9.Future<_i6.PaymentChannelDescriptor>.value(
            _FakePaymentChannelDescriptor_5(
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
      ) as _i9.Future<_i6.PaymentChannelDescriptor>);

  @override
  _i9.Future<bool> fundPaymentChannel(
    _i6.PaymentChannelDescriptor? descriptor,
    String? amount, {
    required _i5.BuildContext? context,
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
        returnValue: _i9.Future<bool>.value(false),
      ) as _i9.Future<bool>);
}

/// A class which mocks [WebSocketChannel].
///
/// See the documentation for Mockito's code generation for more information.
class MockWebSocketChannel extends _i1.Mock implements _i7.WebSocketChannel {
  MockWebSocketChannel() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i9.Future<void> get ready => (super.noSuchMethod(
        Invocation.getter(#ready),
        returnValue: _i9.Future<void>.value(),
      ) as _i9.Future<void>);

  @override
  _i9.Stream<dynamic> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i9.Stream<dynamic>.empty(),
      ) as _i9.Stream<dynamic>);

  @override
  _i7.WebSocketSink get sink => (super.noSuchMethod(
        Invocation.getter(#sink),
        returnValue: _FakeWebSocketSink_6(
          this,
          Invocation.getter(#sink),
        ),
      ) as _i7.WebSocketSink);

  @override
  void pipe(_i8.StreamChannel<dynamic>? other) => super.noSuchMethod(
        Invocation.method(
          #pipe,
          [other],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i8.StreamChannel<S> transform<S>(
          _i8.StreamChannelTransformer<S, dynamic>? transformer) =>
      (super.noSuchMethod(
        Invocation.method(
          #transform,
          [transformer],
        ),
        returnValue: _FakeStreamChannel_7<S>(
          this,
          Invocation.method(
            #transform,
            [transformer],
          ),
        ),
      ) as _i8.StreamChannel<S>);

  @override
  _i8.StreamChannel<dynamic> transformStream(
          _i9.StreamTransformer<dynamic, dynamic>? transformer) =>
      (super.noSuchMethod(
        Invocation.method(
          #transformStream,
          [transformer],
        ),
        returnValue: _FakeStreamChannel_7<dynamic>(
          this,
          Invocation.method(
            #transformStream,
            [transformer],
          ),
        ),
      ) as _i8.StreamChannel<dynamic>);

  @override
  _i8.StreamChannel<dynamic> transformSink(
          _i14.StreamSinkTransformer<dynamic, dynamic>? transformer) =>
      (super.noSuchMethod(
        Invocation.method(
          #transformSink,
          [transformer],
        ),
        returnValue: _FakeStreamChannel_7<dynamic>(
          this,
          Invocation.method(
            #transformSink,
            [transformer],
          ),
        ),
      ) as _i8.StreamChannel<dynamic>);

  @override
  _i8.StreamChannel<dynamic> changeStream(
          _i9.Stream<dynamic> Function(_i9.Stream<dynamic>)? change) =>
      (super.noSuchMethod(
        Invocation.method(
          #changeStream,
          [change],
        ),
        returnValue: _FakeStreamChannel_7<dynamic>(
          this,
          Invocation.method(
            #changeStream,
            [change],
          ),
        ),
      ) as _i8.StreamChannel<dynamic>);

  @override
  _i8.StreamChannel<dynamic> changeSink(
          _i9.StreamSink<dynamic> Function(_i9.StreamSink<dynamic>)? change) =>
      (super.noSuchMethod(
        Invocation.method(
          #changeSink,
          [change],
        ),
        returnValue: _FakeStreamChannel_7<dynamic>(
          this,
          Invocation.method(
            #changeSink,
            [change],
          ),
        ),
      ) as _i8.StreamChannel<dynamic>);

  @override
  _i8.StreamChannel<S> cast<S>() => (super.noSuchMethod(
        Invocation.method(
          #cast,
          [],
        ),
        returnValue: _FakeStreamChannel_7<S>(
          this,
          Invocation.method(
            #cast,
            [],
          ),
        ),
      ) as _i8.StreamChannel<S>);
}

/// A class which mocks [Stream].
///
/// See the documentation for Mockito's code generation for more information.
class MockStream<T> extends _i1.Mock implements _i9.Stream<T> {
  MockStream() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get isBroadcast => (super.noSuchMethod(
        Invocation.getter(#isBroadcast),
        returnValue: false,
      ) as bool);

  @override
  _i9.Future<int> get length => (super.noSuchMethod(
        Invocation.getter(#length),
        returnValue: _i9.Future<int>.value(0),
      ) as _i9.Future<int>);

  @override
  _i9.Future<bool> get isEmpty => (super.noSuchMethod(
        Invocation.getter(#isEmpty),
        returnValue: _i9.Future<bool>.value(false),
      ) as _i9.Future<bool>);

  @override
  _i9.Future<T> get first => (super.noSuchMethod(
        Invocation.getter(#first),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.getter(#first),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.getter(#first),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Future<T> get last => (super.noSuchMethod(
        Invocation.getter(#last),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.getter(#last),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.getter(#last),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Future<T> get single => (super.noSuchMethod(
        Invocation.getter(#single),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.getter(#single),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.getter(#single),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Stream<T> asBroadcastStream({
    void Function(_i9.StreamSubscription<T>)? onListen,
    void Function(_i9.StreamSubscription<T>)? onCancel,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #asBroadcastStream,
          [],
          {
            #onListen: onListen,
            #onCancel: onCancel,
          },
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #listen,
          [onData],
          {
            #onError: onError,
            #onDone: onDone,
            #cancelOnError: cancelOnError,
          },
        ),
        returnValue: _FakeStreamSubscription_9<T>(
          this,
          Invocation.method(
            #listen,
            [onData],
            {
              #onError: onError,
              #onDone: onDone,
              #cancelOnError: cancelOnError,
            },
          ),
        ),
      ) as _i9.StreamSubscription<T>);

  @override
  _i9.Stream<T> where(bool Function(T)? test) => (super.noSuchMethod(
        Invocation.method(
          #where,
          [test],
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.Stream<S> map<S>(S Function(T)? convert) => (super.noSuchMethod(
        Invocation.method(
          #map,
          [convert],
        ),
        returnValue: _i9.Stream<S>.empty(),
      ) as _i9.Stream<S>);

  @override
  _i9.Stream<E> asyncMap<E>(_i9.FutureOr<E> Function(T)? convert) =>
      (super.noSuchMethod(
        Invocation.method(
          #asyncMap,
          [convert],
        ),
        returnValue: _i9.Stream<E>.empty(),
      ) as _i9.Stream<E>);

  @override
  _i9.Stream<E> asyncExpand<E>(_i9.Stream<E>? Function(T)? convert) =>
      (super.noSuchMethod(
        Invocation.method(
          #asyncExpand,
          [convert],
        ),
        returnValue: _i9.Stream<E>.empty(),
      ) as _i9.Stream<E>);

  @override
  _i9.Stream<T> handleError(
    Function? onError, {
    bool Function(dynamic)? test,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #handleError,
          [onError],
          {#test: test},
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.Stream<S> expand<S>(Iterable<S> Function(T)? convert) =>
      (super.noSuchMethod(
        Invocation.method(
          #expand,
          [convert],
        ),
        returnValue: _i9.Stream<S>.empty(),
      ) as _i9.Stream<S>);

  @override
  _i9.Future<dynamic> pipe(_i9.StreamConsumer<T>? streamConsumer) =>
      (super.noSuchMethod(
        Invocation.method(
          #pipe,
          [streamConsumer],
        ),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);

  @override
  _i9.Stream<S> transform<S>(_i9.StreamTransformer<T, S>? streamTransformer) =>
      (super.noSuchMethod(
        Invocation.method(
          #transform,
          [streamTransformer],
        ),
        returnValue: _i9.Stream<S>.empty(),
      ) as _i9.Stream<S>);

  @override
  _i9.Future<T> reduce(
          T Function(
            T,
            T,
          )? combine) =>
      (super.noSuchMethod(
        Invocation.method(
          #reduce,
          [combine],
        ),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.method(
                  #reduce,
                  [combine],
                ),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.method(
                #reduce,
                [combine],
              ),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Future<S> fold<S>(
    S? initialValue,
    S Function(
      S,
      T,
    )? combine,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #fold,
          [
            initialValue,
            combine,
          ],
        ),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<S>(
                this,
                Invocation.method(
                  #fold,
                  [
                    initialValue,
                    combine,
                  ],
                ),
              ),
              (S v) => _i9.Future<S>.value(v),
            ) ??
            _FakeFuture_8<S>(
              this,
              Invocation.method(
                #fold,
                [
                  initialValue,
                  combine,
                ],
              ),
            ),
      ) as _i9.Future<S>);

  @override
  _i9.Future<String> join([String? separator = r'']) => (super.noSuchMethod(
        Invocation.method(
          #join,
          [separator],
        ),
        returnValue: _i9.Future<String>.value(_i11.dummyValue<String>(
          this,
          Invocation.method(
            #join,
            [separator],
          ),
        )),
      ) as _i9.Future<String>);

  @override
  _i9.Future<bool> contains(Object? needle) => (super.noSuchMethod(
        Invocation.method(
          #contains,
          [needle],
        ),
        returnValue: _i9.Future<bool>.value(false),
      ) as _i9.Future<bool>);

  @override
  _i9.Future<void> forEach(void Function(T)? action) => (super.noSuchMethod(
        Invocation.method(
          #forEach,
          [action],
        ),
        returnValue: _i9.Future<void>.value(),
        returnValueForMissingStub: _i9.Future<void>.value(),
      ) as _i9.Future<void>);

  @override
  _i9.Future<bool> every(bool Function(T)? test) => (super.noSuchMethod(
        Invocation.method(
          #every,
          [test],
        ),
        returnValue: _i9.Future<bool>.value(false),
      ) as _i9.Future<bool>);

  @override
  _i9.Future<bool> any(bool Function(T)? test) => (super.noSuchMethod(
        Invocation.method(
          #any,
          [test],
        ),
        returnValue: _i9.Future<bool>.value(false),
      ) as _i9.Future<bool>);

  @override
  _i9.Stream<R> cast<R>() => (super.noSuchMethod(
        Invocation.method(
          #cast,
          [],
        ),
        returnValue: _i9.Stream<R>.empty(),
      ) as _i9.Stream<R>);

  @override
  _i9.Future<List<T>> toList() => (super.noSuchMethod(
        Invocation.method(
          #toList,
          [],
        ),
        returnValue: _i9.Future<List<T>>.value(<T>[]),
      ) as _i9.Future<List<T>>);

  @override
  _i9.Future<Set<T>> toSet() => (super.noSuchMethod(
        Invocation.method(
          #toSet,
          [],
        ),
        returnValue: _i9.Future<Set<T>>.value(<T>{}),
      ) as _i9.Future<Set<T>>);

  @override
  _i9.Future<E> drain<E>([E? futureValue]) => (super.noSuchMethod(
        Invocation.method(
          #drain,
          [futureValue],
        ),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<E>(
                this,
                Invocation.method(
                  #drain,
                  [futureValue],
                ),
              ),
              (E v) => _i9.Future<E>.value(v),
            ) ??
            _FakeFuture_8<E>(
              this,
              Invocation.method(
                #drain,
                [futureValue],
              ),
            ),
      ) as _i9.Future<E>);

  @override
  _i9.Stream<T> take(int? count) => (super.noSuchMethod(
        Invocation.method(
          #take,
          [count],
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.Stream<T> takeWhile(bool Function(T)? test) => (super.noSuchMethod(
        Invocation.method(
          #takeWhile,
          [test],
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.Stream<T> skip(int? count) => (super.noSuchMethod(
        Invocation.method(
          #skip,
          [count],
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.Stream<T> skipWhile(bool Function(T)? test) => (super.noSuchMethod(
        Invocation.method(
          #skipWhile,
          [test],
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.Stream<T> distinct(
          [bool Function(
            T,
            T,
          )? equals]) =>
      (super.noSuchMethod(
        Invocation.method(
          #distinct,
          [equals],
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);

  @override
  _i9.Future<T> firstWhere(
    bool Function(T)? test, {
    T Function()? orElse,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #firstWhere,
          [test],
          {#orElse: orElse},
        ),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.method(
                  #firstWhere,
                  [test],
                  {#orElse: orElse},
                ),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.method(
                #firstWhere,
                [test],
                {#orElse: orElse},
              ),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Future<T> lastWhere(
    bool Function(T)? test, {
    T Function()? orElse,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #lastWhere,
          [test],
          {#orElse: orElse},
        ),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.method(
                  #lastWhere,
                  [test],
                  {#orElse: orElse},
                ),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.method(
                #lastWhere,
                [test],
                {#orElse: orElse},
              ),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Future<T> singleWhere(
    bool Function(T)? test, {
    T Function()? orElse,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #singleWhere,
          [test],
          {#orElse: orElse},
        ),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.method(
                  #singleWhere,
                  [test],
                  {#orElse: orElse},
                ),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.method(
                #singleWhere,
                [test],
                {#orElse: orElse},
              ),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Future<T> elementAt(int? index) => (super.noSuchMethod(
        Invocation.method(
          #elementAt,
          [index],
        ),
        returnValue: _i11.ifNotNull(
              _i11.dummyValueOrNull<T>(
                this,
                Invocation.method(
                  #elementAt,
                  [index],
                ),
              ),
              (T v) => _i9.Future<T>.value(v),
            ) ??
            _FakeFuture_8<T>(
              this,
              Invocation.method(
                #elementAt,
                [index],
              ),
            ),
      ) as _i9.Future<T>);

  @override
  _i9.Stream<T> timeout(
    Duration? timeLimit, {
    void Function(_i9.EventSink<T>)? onTimeout,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #timeout,
          [timeLimit],
          {#onTimeout: onTimeout},
        ),
        returnValue: _i9.Stream<T>.empty(),
      ) as _i9.Stream<T>);
}

/// A class which mocks [WebSocketSink].
///
/// See the documentation for Mockito's code generation for more information.
class MockWebSocketSink extends _i1.Mock implements _i7.WebSocketSink {
  MockWebSocketSink() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i9.Future<dynamic> get done => (super.noSuchMethod(
        Invocation.getter(#done),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);

  @override
  _i9.Future<dynamic> close([
    int? closeCode,
    String? closeReason,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #close,
          [
            closeCode,
            closeReason,
          ],
        ),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);

  @override
  void add(dynamic data) => super.noSuchMethod(
        Invocation.method(
          #add,
          [data],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addError(
    Object? error, [
    StackTrace? stackTrace,
  ]) =>
      super.noSuchMethod(
        Invocation.method(
          #addError,
          [
            error,
            stackTrace,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i9.Future<dynamic> addStream(_i9.Stream<dynamic>? stream) =>
      (super.noSuchMethod(
        Invocation.method(
          #addStream,
          [stream],
        ),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);
}
