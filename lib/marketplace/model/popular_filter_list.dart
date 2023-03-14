class PopularFilterListData {
  PopularFilterListData({
    this.titleTxt = '',
    this.isSelected = false,
  });

  String titleTxt;
  bool isSelected;

  static List<PopularFilterListData> popularFList = <PopularFilterListData>[
    PopularFilterListData(
      titleTxt: 'Face',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Classifier',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Bert',
      isSelected: true,
    ),
    PopularFilterListData(
      titleTxt: 'Body',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Recognition',
      isSelected: false,
    ),
  ];

  static List<PopularFilterListData> accomodationList = [
    PopularFilterListData(
      titleTxt: 'All',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Vision',
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: 'Language',
      isSelected: true,
    ),
    PopularFilterListData(
      titleTxt: 'Other',
      isSelected: false,
    ),
  ];

  static List<PopularFilterListData> sortList = [
    PopularFilterListData(
      titleTxt: "Price: low to high",
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: "Price: high to low",
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: "Runtime: low to high",
      isSelected: false,
    ),
    PopularFilterListData(
      titleTxt: "Runtime: high to low",
      isSelected: true,
    ),
    PopularFilterListData(
      titleTxt: "Users: high to low",
      isSelected: false,
    ),
  ];
}
