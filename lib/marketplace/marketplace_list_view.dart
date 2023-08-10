import 'package:dhali/marketplace/marketplace_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:dhali/marketplace/model/marketplace_list_data.dart';

class MarketplaceListView extends StatelessWidget {
  const MarketplaceListView({
    Key? key,
    required this.callback,
    required this.marketplaceData,
    this.animationController,
    this.animation,
  }) : super(key: key);

  final Function(MarketplaceListData) callback;
  final MarketplaceListData? marketplaceData;
  final AnimationController? animationController;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 50 * (1.0 - animation!.value), 0.0),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 8, bottom: 16),
              child: InkWell(
                key: Key(marketplaceData!.assetID),
                splashColor: Colors.transparent,
                onTap: () => callback(marketplaceData!),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.6),
                        offset: const Offset(4, 4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(16.0)),
                      child: Container(
                        color: MarketplaceAppTheme.buildLightTheme()
                            .colorScheme
                            .background,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              const Spacer(),
                              FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(
                                    marketplaceData!.assetName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 25,
                                    ),
                                  )),
                              const Spacer(),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Text(
                                    marketplaceData!.assetCategories.isNotEmpty
                                        ? marketplaceData!.assetCategories
                                            .toString()
                                        : "",
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Icon(
                                    FontAwesomeIcons.moneyBill1Wave,
                                    size: 14,
                                    color: MarketplaceAppTheme.buildLightTheme()
                                        .primaryColor,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ' ${(marketplaceData!.pricePerRun / 1000000).toStringAsFixed(4)} XRP/run',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Spacer(
                                    flex: 1,
                                  ),
                                  Icon(
                                    FontAwesomeIcons.clock,
                                    size: 14,
                                    color: MarketplaceAppTheme.buildLightTheme()
                                        .primaryColor,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ' ${(marketplaceData!.averageRuntime / 1000).toStringAsFixed(2)} secs/run',
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
