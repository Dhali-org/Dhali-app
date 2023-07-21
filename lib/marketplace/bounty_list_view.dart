import 'package:dhali/marketplace/marketplace_app_theme.dart';
import 'package:dhali/marketplace/model/bounties_list_data.dart';
import 'package:flutter/material.dart';

class BountyListView extends StatelessWidget {
  const BountyListView({
    Key? key,
    required this.callback,
    required this.bountyData,
    this.animationController,
    this.animation,
  }) : super(key: key);

  final Function(BountiesListData) callback;
  final BountiesListData? bountyData;
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
                splashColor: Colors.transparent,
                onTap: () => callback(bountyData!),
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
                          child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Text(
                                bountyData!.title,
                                softWrap: true,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 50,
                                ),
                              )),
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
