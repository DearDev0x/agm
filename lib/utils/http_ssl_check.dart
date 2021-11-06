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
        '3B FC A5 A0 5C 1A B5 AC EF 91 83 8A 32 C8 9F CF 2C FA AC A8 2F 8E 9C F1 55 D1 69 85 B2 72 38 F6';
    int timeout = 60;
    SHA sha = SHA.SHA256;
    List<String> allowedShA1FingerprintList = new List();
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
