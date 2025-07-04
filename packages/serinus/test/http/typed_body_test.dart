import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {
  @override
  String get name => 'http';
}

class _MockContext extends Mock implements RequestContext {
  final Body _body;

  _MockContext(this._body);

  @override
  Body get body => _body;
}

class _MockModelProvider extends Mock implements ModelProvider {
  @override
  Map<Type, Function> get fromJsonModels =>
      {TestObject: (json) => TestObject.fromJson(json)};

  @override
  Object from(Type model, Map<String, dynamic> json) {
    if (model == TestObject) {
      return TestObject.fromJson(json);
    }
    throw UnsupportedError('Model not supported');
  }
}

class TestObject {
  final String name;

  TestObject(this.name);

  factory TestObject.fromJson(Map<String, dynamic> json) {
    return TestObject(json['name']);
  }
}

final config = ApplicationConfig(
    serverAdapter: _MockAdapter());

void main() {
  group('Typed Body', () {
    test(
        'when the body type is an available body the request handler should provide it',
        () {
      final RequestHandler requestHandler =
          RequestHandler(Router(), ModulesContainer(config), config);
      var body = requestHandler.getBodyValue(
          _MockContext(Body(ContentType.text, text: 'test')), String);
      expect(body, 'test');

      body = requestHandler.getBodyValue(
          _MockContext(
              Body(ContentType.json, json: JsonBodyObject({'test': 'test'}))),
          Map);

      expect(body, {'test': 'test'});

      body = requestHandler.getBodyValue(
          _MockContext(Body(ContentType.json, json: JsonList(['test']))), List);

      body = requestHandler.getBodyValue(
          _MockContext(Body(ContentType.binary, bytes: [1, 2, 3])), Uint8List);

      expect(body, [1, 2, 3]);

      body = requestHandler.getBodyValue(
          _MockContext(Body(
              ContentType.parse('application/x-www-form-urlencoded'),
              formData: FormData(fields: {'test': 'test'}))),
          FormData);

      expect(body.values, {
        'fields': {'test': 'test'},
        'files': {}
      });
    });

    test(
        'if the body type is not the same as the current body value then a [PreconditionFailedException] should be thrown',
        () {
      final RequestHandler requestHandler =
          RequestHandler(Router(), ModulesContainer(config), config);
      expect(
          () => requestHandler.getBodyValue(
              _MockContext(Body(ContentType.text, text: 'test')), Map),
          throwsA(isA<PreconditionFailedException>()));
    });

    test(
        'if the body type is in the [ModelProvider] then the body should be converted to the model',
        () {
      final modelProviderConfig = ApplicationConfig(
          serverAdapter: _MockAdapter(),
          modelProvider: _MockModelProvider());
      final RequestHandler requestHandler = RequestHandler(
          Router(), ModulesContainer(modelProviderConfig), modelProviderConfig);
      final body = requestHandler.getBodyValue(
          _MockContext(
              Body(ContentType.json, json: JsonBodyObject({'name': 'test'}))),
          TestObject);
      expect(body.name, 'test');
    });

    test(
        'if the body type is not in the [ModelProvider] then a [PreconditionFailedException] should be thrown',
        () {
      final modelProviderConfig = ApplicationConfig(
          serverAdapter: _MockAdapter(),
          modelProvider: _MockModelProvider());
      final RequestHandler requestHandler = RequestHandler(
          Router(), ModulesContainer(modelProviderConfig), modelProviderConfig);
      expect(
          () => requestHandler.getBodyValue(
              _MockContext(Body(ContentType.json,
                  json: JsonBodyObject({'name': 'test'}))),
              String),
          throwsA(isA<PreconditionFailedException>()));
    });

    test(
        'if the body type is in the [ModelProvider] and the raw body is a FormData then the body should be converted to the model',
        () {
      final modelProviderConfig = ApplicationConfig(
          serverAdapter: _MockAdapter(),
          modelProvider: _MockModelProvider());
      final RequestHandler requestHandler = RequestHandler(
          Router(), ModulesContainer(modelProviderConfig), modelProviderConfig);
      final body = requestHandler.getBodyValue(
          _MockContext(Body(
              ContentType.parse('application/x-www-form-urlencoded'),
              formData: FormData(fields: {'name': 'test'}))),
          TestObject);
      expect(body.name, 'test');
    });
  });
}
