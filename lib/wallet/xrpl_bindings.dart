@JS('xrpl')
library xrpl;

import 'package:flutter/material.dart';
import 'package:js/js.dart';

@JS()
external String authorizeChannel(
    Wallet wallet, String channelId, String amount);

@JS()
class ClientOptions {
  external ClientOptions();
}

@JS()
class Client {
  external Client(String server, [ClientOptions clientOptions]);
  external dynamic connect();
  external dynamic disconnect();
  external dynamic fundWallet(Wallet? wallet);
  external dynamic getXrpBalance(String address);
  external dynamic autofill(dynamic transactionOptions);
  external dynamic submitAndWait(
      dynamic transaction, SignTransactionOptions options);
  external dynamic request(dynamic request);
}

@JS()
@anonymous
class WalletOptions {
  external String? masterAddress;
  external String? seed;

  external factory WalletOptions({String? masterAdress, String? seed});
}

@JS()
@anonymous
class WalletFromMnemonicOptions {
  external dynamic algorithm;
  external String? derivationPath;
  external String? masterAddress;
  external dynamic mnemonicEncoding;

  external factory WalletFromMnemonicOptions({
    dynamic algorithm,
    String? derivationPath,
    String? masterAddress,
    dynamic mnemonicEncoding,
  });
}

@JS()
@anonymous
class PaymentChannelCreate {
  external String Account;
  external String
      TransactionType; // TODO: No way I'm aware of to initialise this to 'PaymentChannelCreate' since it and the factory below are external (which is required for interop),  At the moment, we have to explicitly assign it.
  external String Amount;
  external String Destination;
  external int SettleDelay;
  external String? PublicKey;

  external factory PaymentChannelCreate({
    String Account,
    String TransactionType,
    String Amount,
    String Destination,
    int SettleDelay,
    String? PublicKey,
  });
}

@JS()
@anonymous
class AccountChannelsRequest {
  external String account;
  external String? destination_account;
  external String
      command; // TODO: No way I'm aware of to initialise this to 'account_channels' since it and the factory below are external (which is required for interop),  At the moment, we have to explicitly assign it.
  external String? ledger_hash;
  external dynamic ledger_index;
  external int? limit;
  external dynamic marker;

  external factory AccountChannelsRequest({
    String account,
    String? destination_account,
    String command,
    String? ledger_hash,
    dynamic ledger_index,
    int? limit,
    dynamic marker,
  });
}

@JS()
class Wallet {
  external Wallet(String publicKey, String privateKey, [WalletOptions opts]);
  external static Wallet fromMnemonic(String mnemonic,
      [WalletFromMnemonicOptions opts]);
  external dynamic sign(dynamic transaction);
  external String address;
  external String publicKey;
}

@JS()
@anonymous
class SignTransactionOptions {
  external bool autofill;
  external bool failHard;
  external Wallet wallet;

  external factory SignTransactionOptions({
    bool autofill,
    bool failHard,
    Wallet wallet,
  });
}

@JS()
@anonymous
class NFTSellOffersRequest {
  external int? api_version;
  external String
      command; // TODO: No way I'm aware of to initialise this to 'nft_sell_offers' since it and the factory below are external (which is required for interop),  At the moment, we have to explicitly assign it.
  external String? id;
  external String nft_id;

  external factory NFTSellOffersRequest({
    int api_version,
    String command,
    String? id,
    String nft_id,
  });
}

@JS()
@anonymous
class NFTSellOffersResult {
  external String nft_id;
  external dynamic offers;

  external factory NFTSellOffersResult({
    String nft_id,
    dynamic offers,
  });
}

@JS()
@anonymous
class NFTSellOffersResponse {
  external int? api_version;
  external bool? forwarded;
  external String id;
  external NFTSellOffersResult result;
  external String? status;
  external String type;
  external dynamic warning;
  external dynamic warnings;

  external factory NFTSellOffersResponse({
    int? api_version,
    bool? forwarded,
    String id,
    NFTSellOffersResult result,
    String? status,
    String type,
    dynamic warning,
    dynamic warnings,
  });
}

@JS()
@anonymous
class NFTOfferAccept {
  external String Account;
  external String? AccountTxnID;
  external String? Fee;
  external dynamic Flags;
  external int? LastLedgerSequence;
  external dynamic Memos;
  external dynamic NFTokenBrokerFee;
  external String? NFTokenBuyOffer;
  external String? NFTokenSellOffer;
  external int? Sequence;
  external dynamic Signers;
  external String? SigningPublicKey;
  external int? SourceTag;
  external String
      TransactionType; // TODO: No way I'm aware of to initialise this to 'NFTokenAcceptOffer' since it and the factory below are external (which is required for interop),  At the moment, we have to explicitly assign it.
  external String? TxnSignature;

  external factory NFTOfferAccept({
    String Account,
    String? AccountTxnID,
    String? Fee,
    dynamic Flags,
    int? LastLedgerSequence,
    dynamic Memos,
    dynamic NFTokenBrokerFee,
    String? NFTokenBuyOffer,
    String? NFTokenSellOffer,
    int? Sequence,
    dynamic Signers,
    String? SigningPublicKey,
    int? SourceTag,
    String TransactionType,
    String? TxnSignature,
  });
}
