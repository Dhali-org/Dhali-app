import "package:universal_html/html.dart";

class AssetModel {
  final File imageFile;
  final String fileName;
  String modelName;
  final String mime;
  final int size;

  AssetModel({
    required this.imageFile,
    required this.fileName,
    required this.modelName,
    required this.mime,
    required this.size,
  });
}
