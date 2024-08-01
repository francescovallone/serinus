import 'package:serinus_sse/src/sse_provider.dart';

mixin OnSseConnect on SseProvider {
  void onConnect(String clientId) {}
}
