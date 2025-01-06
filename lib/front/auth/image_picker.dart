import 'package:flutter/material.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

Future<List<Asset>> loadAssets({
  required String error,
  required int maxNumOfPhotos,
  required int minNumOfPhotos,
}) async {
  List<Asset> resultList = <Asset>[];

  const AlbumSetting albumSetting = AlbumSetting(
    fetchResults: {
      PHFetchResult(
        type: PHAssetCollectionType.smartAlbum,
        subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary,
      ),
      PHFetchResult(
        type: PHAssetCollectionType.smartAlbum,
        subtype: PHAssetCollectionSubtype.smartAlbumFavorites,
      ),
      PHFetchResult(
        type: PHAssetCollectionType.album,
        subtype: PHAssetCollectionSubtype.albumRegular,
      ),
      PHFetchResult(
        type: PHAssetCollectionType.smartAlbum,
        subtype: PHAssetCollectionSubtype.smartAlbumSelfPortraits,
      ),
      PHFetchResult(
        type: PHAssetCollectionType.smartAlbum,
        subtype: PHAssetCollectionSubtype.smartAlbumPanoramas,
      ),
      PHFetchResult(
        type: PHAssetCollectionType.smartAlbum,
        subtype: PHAssetCollectionSubtype.smartAlbumVideos,
      ),
    },
  );

  SelectionSetting selectionSetting = SelectionSetting(
    min: minNumOfPhotos,
    max: maxNumOfPhotos,
    unselectOnReachingMax: true,
  );

  const DismissSetting dismissSetting = DismissSetting(
    enabled: true,
    allowSwipe: true,
  );
  const ListSetting listSetting = ListSetting(
    spacing: 5,
    cellsPerRow: 4,
  );

  const AssetsSetting assetsSetting = AssetsSetting(
    supportedMediaTypes: {MediaTypes.video, MediaTypes.image},
  );

  final CupertinoSettings iosSettings = CupertinoSettings(
    fetch: const FetchSetting(album: albumSetting, assets: assetsSetting),
    selection: selectionSetting,
    dismiss: dismissSetting,
    list: listSetting,
  );
  try {
    resultList = await MultiImagePicker.pickImages(
      selectedAssets: resultList,
      iosOptions: IOSOptions(
        doneButton: UIBarButtonItem(
          title: 'Confirm',
        ),
        cancelButton: UIBarButtonItem(
          title: 'Cancel',
        ),
        settings: iosSettings,
      ),
      androidOptions: AndroidOptions(
        actionBarTitle: 'Select Photo',
        allViewTitle: 'All Photos',
        useDetailsView: false,
      ),
    );
  } on Exception catch (e) {
    error = e.toString();
  }

  return resultList;
}

Widget buildGridView({
  required List<Asset> images,
  required double width,
  required double height,
}) {
  return GridView.count(
    crossAxisCount: images.length < 3 ? images.length : 3,
    mainAxisSpacing: height * 0.011,
    crossAxisSpacing: width * 0.025,
    children: List.generate(
      images.length,
      (index) {
        Asset asset = images[index];
        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: AssetThumb(
            asset: asset,
            width: (width * 0.763).toInt(),
            height: (height * 0.352).toInt(),
          ),
        );
      },
    ),
  );
}
