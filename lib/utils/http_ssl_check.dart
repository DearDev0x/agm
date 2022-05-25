import 'package:ssl_pinning_plugin/ssl_pinning_plugin.dart';

class HttpSslCheck {
  final String url;
  HttpSslCheck({
    this.url,
  });

  check() async {
    HttpMethod httpMethod = HttpMethod.Get;
    Map<String, String> headerHttp = new Map();
    String allowedSHAFingerprint =
        'D6 01 AD 5E FB 19 26 16 AE 51 89 70 79 E3 9F 81 5E FE 0D DC 5E C2 E1 2C 0A DC F0 56 30 54 E3 53';
    int timeout = 60;
    SHA sha = SHA.SHA256;
    List<String> allowedShA1FingerprintList = [];
    allowedShA1FingerprintList.add(allowedSHAFingerprint);

    try {
      String checkMsg = await SslPinningPlugin.check(
          serverURL: this.url,
          headerHttp: headerHttp,
          httpMethod: httpMethod,
          sha: sha,
          allowedSHAFingerprints: allowedShA1FingerprintList,
          timeout: timeout);
      print(checkMsg);
      if (checkMsg == 'CONNECTION_SECURE') {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}
