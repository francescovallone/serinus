import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _MockIncomingMessage extends Mock implements IncomingMessage {}

class _MockModelProvider extends Mock implements ModelProvider {
  @override
  Map<String, Function> get fromJsonModels => {
    'TestObject': (json) => TestObject.fromJson(json),
  };

  @override
  Object from(String model, Map<String, dynamic> json) {
    return fromJsonModels['$model']?.call(json);
  }
}

class TestObject {
  final String name;

  TestObject(this.name);

  factory TestObject.fromJson(Map<String, dynamic> json) {
    return TestObject(json['name']);
  }
}

class MockHttpHeaders extends Mock implements HttpHeaders {}

Request _buildRequest({ContentType? contentType}) {
  final incoming = _MockIncomingMessage();
  final effectiveContentType = contentType ?? jsonContentType;
  when(() => incoming.queryParameters).thenReturn({});
  when(() => incoming.headers).thenReturn(SerinusHeaders(MockHttpHeaders()));
  when(() => incoming.contentType).thenReturn(effectiveContentType);
  when(() => incoming.method).thenReturn('POST');
  when(() => incoming.path).thenReturn('/');
  when(() => incoming.uri).thenReturn(Uri.parse('http://localhost'));
  when(() => incoming.id).thenReturn('req-1');
  when(() => incoming.host).thenReturn('localhost');
  when(() => incoming.hostname).thenReturn('localhost');
  when(() => incoming.port).thenReturn(3000);
  when(() => incoming.cookies).thenReturn(const []);
  when(() => incoming.segments).thenReturn(const []);
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
  return Request(incoming);
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  group('RequestContext body typing', () {
    test('preserves string bodies when explicitly typed', () {
      final request = _buildRequest(contentType: ContentType.text);
      final context = RequestContext<String>.withBody(
        request,
        'hello',
        <Type, Provider>{},
        <ValueToken, Object?>{},
        <Type, Object>{},
        explicitType: String,
      );

      expect(context.body, equals('hello'));
      expect(request.body, equals('hello'));
    });

    test('converts binary payloads to Uint8List', () {
      final request = _buildRequest(contentType: ContentType.binary);
      final context = RequestContext<Uint8List>.withBody(
        request,
        Uint8List(0),
        <Type, Provider>{},
        <ValueToken, Object?>{},
        <Type, Object>{},
        explicitType: Uint8List,
      );

      context.body = [1, 2, 3];

      expect(context.body.toList(), equals([1, 2, 3]));
    });

    test('casts dynamic list to typed list of maps', () {
      final request = _buildRequest();
      final context = RequestContext<dynamic>.withBody(
        request,
        [
          {'name': 'serinus'},
        ],
        <Type, Provider>{},
        <ValueToken, Object?>{},
        <Type, Object>{},
        explicitType: List<Map<String, dynamic>>,
      );

      final body = context.body as List;

      expect(body, hasLength(1));
      expect(body.first, isA<Map<String, dynamic>>());
      expect((body.first as Map<String, dynamic>)['name'], equals('serinus'));
    });

    test('casts dynamic list to typed list of strings by using bodyAsList', () {
      final request = _buildRequest();
      final context = RequestContext<dynamic>.withBody(
        request,
        ['data', 'info', 'serinus'],
        <Type, Provider>{},
        <ValueToken, Object?>{},
        <Type, Object>{},
      );

      final body = context.bodyAsList<String>();

      expect(body, hasLength(3));
      expect(body.first, isA<String>());
      expect(body.last, equals('serinus'));
    });

    test('throws when body cannot be converted to expected type', () {
      final request = _buildRequest();
      final context = RequestContext<dynamic>.withBody(
        request,
        1,
        <Type, Provider>{},
        <ValueToken, Object?>{},
        <Type, Object>{},
        explicitType: int,
      );

      expect(
        () => context.body = {'unexpected': true},
        throwsA(isA<BadRequestException>()),
      );
    });

    test('leverages model provider conversions', () {
      final request = _buildRequest();
      final modelProvider = _MockModelProvider();
      final context = RequestContext<dynamic>.withBody(
        request,
        {'name': 'bird'},
        <Type, Provider>{},
        <ValueToken, Object?>{},
        <Type, Object>{},
        modelProvider: modelProvider,
        explicitType: TestObject,
      );

      expect(context.body, isA<TestObject>());
      expect((context.body as TestObject).name, equals('bird'));
    });
  });
}
