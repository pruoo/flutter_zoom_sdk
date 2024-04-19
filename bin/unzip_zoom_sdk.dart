import 'dart:core';
import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  var location = Platform.script.toString();
  var isNewFlutter = location.contains(".snapshot");
  if (isNewFlutter) {
    var sp = Platform.script.toFilePath();
    var sd = sp.split(Platform.pathSeparator);
    sd.removeLast();
    var scriptDir = sd.join(Platform.pathSeparator);
    var packageConfigPath = [scriptDir, '..', '..', '..', 'package_config.json']
        .join(Platform.pathSeparator);
    var jsonString = File(packageConfigPath).readAsStringSync();
    Map<String, dynamic> packages = jsonDecode(jsonString);
    var packageList = packages["packages"];
    String? zoomFileUri;
    for (var package in packageList) {
      if (package["name"] == "flutter_zoom_sdk") {
        zoomFileUri = package["rootUri"];
        break;
      }
    }
    if (zoomFileUri == null) {
      print("flutter_zoom_sdk package not found!");
      return;
    }
    location = zoomFileUri;
  }
  if (Platform.isWindows) {
    location = location.replaceFirst("file:///", "");
  } else {
    location = location.replaceFirst("file://", "");
  }
  if (!isNewFlutter) {
    location = location.replaceFirst("/bin/unzip_zoom_sdk.dart", "");
  }

  await checkAndDownloadSDK(location);

  print('Complete');
}

Future<void> checkAndDownloadSDK(String location) async {
  // * ios sdk
  var iosSDKFile = location +
      '/ios/MobileRTC.xcframework/ios-arm64_armv7/MobileRTC.framework/MobileRTC';

  bool exists = await File(iosSDKFile).exists();

  if (!exists) {
    await downloadFile(
        Uri.parse(
          // ! at the end of the url, ensure "?dl=1"
          // "https://www.dropbox.com/s/eq9yw94uwqx2tl2/MobileRTC%20Five%20Ten%203?dl=1", //5.10.3
          "https://www.dropbox.com/s/gfkj4hewwnb0qwa/MobileRTC%20Five%20Eleven%203?dl=1", //5.11.3
          // 'https://www.dropbox.com/s/q7l6ryp870ggxx5/MobileRTC?dl=1'
          // 'https://www.dropbox.com/s/a5vfh2m543t15k8/MobileRTC?dl=1'
          // "https://www.dropbox.com/s/kiypi6wrtzu3p3t/MobileRTC?dl=1", //5.13.3
          // "https://www.dropbox.com/scl/fo/1amxdjylbnkig2ky1kw42/h?dl=1", // 5.14.0
        ),
        iosSDKFile);
  }

  // * ios bundle
  var iosBundleFile = location +
      '/ios/MobileRTCResources.bundle/ios-arm64_armv7/MobileRTCResources.bundle/MobileRTC';
  bool bundleExists = await File(iosBundleFile).exists();

  if (!bundleExists) {
    await downloadFile(
        Uri.parse(
          // ! at the end of the url, ensure "?dl=1"
          "https://www.dropbox.com/s/bcdciisq6lk6irc/MobileRTCResources.bundle.zip?dl=1", // 5.14.0
        ),
        iosBundleFile);
  }
  //

  // * ios simulator
  var iosSimulateSDKFile = location +
      '/ios/MobileRTC.xcframework/ios-i386_x86_64-simulator/MobileRTC.framework/MobileRTC';
  exists = await File(iosSimulateSDKFile).exists();

  if (!exists) {
    await downloadFile(
        Uri.parse('https://www.dropbox.com/s/alk03qxiolurxf8/MobileRTC?dl=1'),
        iosSimulateSDKFile);
  }

  // * android
  var androidCommonLibFile = location + '/android/libs/commonlib.aar';
  exists = await File(androidCommonLibFile).exists();
  if (!exists) {
    await downloadFile(
        Uri.parse(
          "https://storage.cloud.google.com/pruoo-cloud-sdk/commonlib.aar?dl=1", //5.12.8
          // "https://www.dropbox.com/s/pc5h8dxkf5t1p0j/commonlib%20-%20five%20eleven%20ten%20-%20aar.aar?dl=1" // 5.13.10
          // "https://www.dropbox.com/s/fxiqvt6j07pf2cr/commonlib.aar?dl=1"
          // 'https://www.dropbox.com/s/i5fww50elzrphra/commonlib.aar?dl=1'
        ),
        androidCommonLibFile);
  }
  var androidRTCLibFile = location + '/android/libs/mobilertc.aar';
  exists = await File(androidRTCLibFile).exists();
  if (!exists) {
    await downloadFile(
        Uri.parse(
          "https://storage.cloud.google.com/pruoo-cloud-sdk/mobilertc.aar?dl=1", // 5.12.8
          // "https://www.dropbox.com/s/3qmscuct756nhp0/mobilertc%20-%20five%20eleven%20ten%20-%20aar.aar?dl=1", // 5.13.10
          // "https://www.dropbox.com/s/e9f7qz2ajk42tft/mobilertc.aar?dl=1"
          // 'https://www.dropbox.com/s/ahh06pva216szc1/mobilertc.aar?dl=1'
        ),
        androidRTCLibFile);
  }
}

Future<void> downloadFile(Uri uri, String savePath) async {
  print('Download ${uri.toString()} to $savePath');
  File destinationFile = await File(savePath).create(recursive: true);

  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  await response.pipe(destinationFile.openWrite());
}
