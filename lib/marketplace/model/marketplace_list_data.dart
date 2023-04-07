class MarketplaceListData {
  MarketplaceListData({
    required this.assetID,
    this.imagePath = '',
    this.assetName = '',
    this.assetCategories = const [],
    this.averageRuntime = 1.8,
    this.reviews = 80,
    this.numberOfSuccessfullRequests = 4.5,
    this.pricePerRun = 180,
  });

  String assetID;
  String imagePath;
  String assetName;
  List<dynamic> assetCategories;
  double averageRuntime;
  double numberOfSuccessfullRequests;
  int reviews;
  int pricePerRun;

  static List<MarketplaceListData> marketplaceList = <MarketplaceListData>[
    MarketplaceListData(
      assetID: "",
      assetName: 'bert-base-uncased',
      assetCategories: ['Fill-Mask'],
      averageRuntime: 0.12,
      reviews: 80,
      numberOfSuccessfullRequests: 4.4,
      pricePerRun: 180,
    ),
    MarketplaceListData(
      assetID: "",
      assetName: 'gpt2',
      assetCategories: ['Text generation'],
      averageRuntime: 0.2,
      reviews: 74,
      numberOfSuccessfullRequests: 4.5,
      pricePerRun: 200,
    ),
    MarketplaceListData(
      assetID: "",
      assetName: 'gpt3',
      assetCategories: ['Text generation'],
      averageRuntime: 0.31,
      reviews: 62,
      numberOfSuccessfullRequests: 4.0,
      pricePerRun: 60,
    ),
    MarketplaceListData(
      assetID: "",
      assetName: 'Mobilenet V2',
      assetCategories: ['Object detector'],
      averageRuntime: 0.004,
      reviews: 90,
      numberOfSuccessfullRequests: 4.4,
      pricePerRun: 170,
    ),
    MarketplaceListData(
      assetID: "",
      assetName: 'VGG',
      assetCategories: ['Face detector'],
      averageRuntime: 0.01,
      reviews: 240,
      numberOfSuccessfullRequests: 4.5,
      pricePerRun: 200,
    ),
  ];
}
