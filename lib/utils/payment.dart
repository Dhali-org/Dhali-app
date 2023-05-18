import 'package:dhali/config.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';

Map<String, String> preparePayment(
    {required XRPLWallet? Function() getWallet,
    required String destinationAddress,
    required String authAmount,
    required String channelId}) {
  return {
    Config.config!["PAYMENT_CLAIM_KEYS"]["ACCOUNT"]: getWallet()!.address,
    Config.config!["PAYMENT_CLAIM_KEYS"]["DESTINATION_ACCOUNT"]:
        destinationAddress,
    Config.config!["PAYMENT_CLAIM_KEYS"]["AUTHORIZED_AMOUNT"]: authAmount,
    Config.config!["PAYMENT_CLAIM_KEYS"]["SIGNATURE"]:
        getWallet()!.sendDrops(authAmount, channelId),
    Config.config!["PAYMENT_CLAIM_KEYS"]["CHANNEL_ID"]: channelId
  };
}
