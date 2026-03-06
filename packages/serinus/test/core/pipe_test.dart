import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _MockIncomingMessage extends Mock implements IncomingMessage {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

Request _buildRequest({
  Map<String, String> queryParameters = const {},
  Map<String, dynamic> params = const {},
}) {
  final incoming = _MockIncomingMessage();
  when(() => incoming.queryParameters).thenReturn(queryParameters);
  when(() => incoming.headers).thenReturn(SerinusHeaders(_MockHttpHeaders()));
  when(() => incoming.contentType).thenReturn(ContentType.text);
  when(() => incoming.method).thenReturn('GET');
  when(() => incoming.path).thenReturn('/test');
  when(() => incoming.uri).thenReturn(Uri.parse('http://localhost/test'));
  when(() => incoming.id).thenReturn('req-pipe-1');
  when(() => incoming.host).thenReturn('localhost');
  when(() => incoming.hostname).thenReturn('localhost');
  when(() => incoming.port).thenReturn(3000);
  when(() => incoming.cookies).thenReturn(const []);
  when(() => incoming.segments).thenReturn(const ['test']);
  when(() => incoming.clientInfo).thenReturn(null);
  when(() => incoming.contentLength).thenReturn(0);
  when(() => incoming.isWebSocket).thenReturn(false);
  when(() => incoming.webSocketKey).thenReturn('');
  when(() => incoming.body()).thenReturn('');
  when(() => incoming.json()).thenReturn(null);
  when(() => incoming.bytes()).thenAnswer((_) async => Uint8List(0));
  when(() => incoming.stream()).thenAnswer((_) => const Stream.empty());
  when(() => incoming.formData()).thenAnswer(
    (_) async => FormData(
      contentType: ContentType('application', 'x-www-form-urlencoded'),
    ),
  );
  return Request(incoming, params);
}

ExecutionContext<HttpArgumentsHost> _buildContext(Request request) {
  return ExecutionContext(
    HostType.http,
    <Type, Provider>{},
    <ValueToken, Object?>{},
    <Type, Object>{},
    HttpArgumentsHost(request),
  );
}

void main() {
  group('$ParseBoolPipe', () {
    test('parses true and false query values', () async {
      final request = _buildRequest(queryParameters: {'active': 'false'});
      final context = _buildContext(request);

      await ParseBoolPipe(
        'active',
        bindingType: PipeBindingType.query,
      ).transform(context);

      expect(request.query['active'], isFalse);
    });

    test('parses true and false params values', () async {
      final request = _buildRequest(params: {'enabled': 'true'});
      final context = _buildContext(request);

      await ParseBoolPipe(
        'enabled',
        bindingType: PipeBindingType.params,
      ).transform(context);

      expect(request.params['enabled'], isTrue);
    });

    test('throws on invalid query values', () async {
      final request = _buildRequest(queryParameters: {'active': 'yes'});
      final context = _buildContext(request);

      expect(
        () => ParseBoolPipe(
          'active',
          bindingType: PipeBindingType.query,
        ).transform(context),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('throws on invalid params values', () async {
      final request = _buildRequest(params: {'enabled': 'nope'});
      final context = _buildContext(request);

      expect(
        () => ParseBoolPipe(
          'enabled',
          bindingType: PipeBindingType.params,
        ).transform(context),
        throwsA(isA<BadRequestException>()),
      );
    });
  });
}
