import 'package:xrpl/xrpl.dart';
import 'package:flutter/material.dart';

import 'package:dhali/wallet/xrpl_wallet.dart';

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen(
      {super.key,
      required this.title,
      required this.getWallet,
      required this.setWallet});

  final String title;
  final XRPLWallet? Function() getWallet;
  final Function(XRPLWallet) setWallet;

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

// TODO: Metamask-style phrase creation and verification
class _WalletHomeScreenState extends State<WalletHomeScreen> {
  // TODO: pull the fields below from wallet
  String _publicKey = "";
  String? _mnemonicState;

  final _mnemonicFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    if (widget.getWallet() == null) {
      return Scaffold(
        body: Center(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60.0),
                  child: Form(
                    key: _mnemonicFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              hintText: "Input your memorable words here.",
                            ),
                            validator: (value) {
                              const String errorMessage =
                                  'You must have at least 12 memorable words for your wallet.';
                              if (value == null || value.isEmpty) {
                                return errorMessage;
                              }

                              final whitespaceRegex = RegExp(r"\s+");
                              final leadingWhitespaceRegex = RegExp(r"^\s");
                              final trailingWhitespaceRegex = RegExp(r"\s$");

                              String cleanupWhitespace(String input) => value
                                  .replaceAll(whitespaceRegex, " ")
                                  .replaceAll(leadingWhitespaceRegex, "")
                                  .replaceAll(trailingWhitespaceRegex, "");

                              if (cleanupWhitespace(value).split(' ').length <
                                  12) {
                                return errorMessage;
                              }
                              return null;
                            },
                            onChanged: (String mnemonic) {
                              if (_mnemonicFormKey.currentState!.validate()) {
                                setState(() {
                                  _mnemonicState = mnemonic;
                                });
                              } else {
                                setState(() {
                                  _mnemonicState = null;
                                });
                              }
                            }),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 25),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Stack(
                                children: <Widget>[
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: <Color>[
                                            Color(0xFF652EC8),
                                            Color(0xFF8D68CE),
                                            Color(0xFFB7AAD0),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(.0),
                                      textStyle: const TextStyle(fontSize: 20),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_mnemonicState != null) {
                                          // TODO: 'testMode' to 'false' for release
                                          var wallet = XRPLWallet(
                                              _mnemonicState!,
                                              testMode: true);
                                          widget.setWallet(wallet);
                                          _publicKey =
                                              widget.getWallet()!.publicKey();
                                        }
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 50.0, vertical: 25),
                                      child: Text(
                                        'Retrieve your wallet',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: getGeneratedWidget(widget.getWallet()!),
        ),
      );
    }
  }
}

Widget getGeneratedWidget(XRPLWallet wallet) {
  return ListView(
    shrinkWrap: true,
    children: <Widget>[
      //const Center(
      //  child: const Padding(
      //padding: EdgeInsets.symmetric(horizontal: 200.0,
      //                        vertical: 100.0),
      //    child: BalanceChart(),
      //  )
      //),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25.0),
          child: ValueListenableBuilder<String?>(
              valueListenable: wallet.balance,
              builder: (BuildContext context, String? balance, Widget? _) {
                if (balance == null) {
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Loading balance: ",
                            style: TextStyle(fontSize: 25)),
                        CircularProgressIndicator()
                      ]);
                }
                return SelectableText('Your balance: $balance',
                    style: const TextStyle(fontSize: 25));
              }),
        ),
      ),
      Center(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            child: SelectableText(
              'Your classic address: ${wallet.address}',
              style: const TextStyle(fontSize: 25),
            )),
      )
    ],
  );
}
