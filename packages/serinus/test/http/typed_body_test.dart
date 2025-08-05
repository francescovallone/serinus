import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/routes/route_execution_context.dart';
import 'package:serinus/src/routes/route_response_controller.dart';
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
      final executionContext = RouteExecutionContext(
        RouteResponseController(_MockAdapter()),
      );

      var body = executionContext.resolveBody(
        String,
        _MockContext(StringBody('test'))
      );
      expect(body, 'test');

      body = executionContext.resolveBody(
        Map,
        _MockContext(JsonBodyObject({'test': 'test'}))
      );

      expect(body, {'test': 'test'});

      body = executionContext.resolveBody(
          List,
          _MockContext(JsonList(['test']))
      );

      body = executionContext.resolveBody(
          Uint8List,
          _MockContext(RawBody(
              [1, 2, 3]
          ))
      );

      expect(body, [1, 2, 3]);

      body = executionContext.resolveBody(
          Map,
          _MockContext(FormDataBody(
              FormData(fields: {'test': 'test'}, contentType: ContentType.parse('application/x-www-form-urlencoded')))
          )
      );

      expect(body, {'test': 'test'});

      body = executionContext.resolveBody(
          Map,
          _MockContext(FormDataBody(
              FormData(fields: {'test': 'test'}, files: {}, contentType: ContentType.parse('multipart/form-data')))
          )
      );

      expect(body, {
        'fields': {'test': 'test'},
        'files': {}
      });
    });

    test(
        'if the body type is not the same as the current body value then a [PreconditionFailedException] should be thrown',
        () {
      final executionContext = RouteExecutionContext(
        RouteResponseController(_MockAdapter()),
      );
      expect(
          () => executionContext.resolveBody(
              String,
              _MockContext(JsonBodyObject({'test': 'test'}))
          ),
          throwsA(isA<PreconditionFailedException>()));
    });

    test(
        'if the body type is in the [ModelProvider] then the body should be converted to the model',
        () {
      final executionContext = RouteExecutionContext(
        RouteResponseController(_MockAdapter()),
        modelProvider: _MockModelProvider()
      );
      
      final body = executionContext.resolveBody(
          TestObject,
          _MockContext(JsonBodyObject({'name': 'test'}))
      );
      expect(body.name, 'test');
    });

    test(
        'if the body type is not in the [ModelProvider] then a [PreconditionFailedException] should be thrown',
        () {
      final executionContext = RouteExecutionContext(
        RouteResponseController(_MockAdapter()),
        modelProvider: _MockModelProvider()
      );
      expect(
          () => executionContext.resolveBody(
              TestObject,
              _MockContext(StringBody('test')),
            ),
          throwsA(isA<PreconditionFailedException>()));
    });

    test(
        'if the body type is in the [ModelProvider] and the raw body is a FormData then the body should be converted to the model',
        () {
      final executionContext = RouteExecutionContext(
        RouteResponseController(_MockAdapter()),
        modelProvider: _MockModelProvider()
      );

      final body = executionContext.resolveBody(
          TestObject,
          _MockContext(FormDataBody(
              FormData(fields: {'name': 'test'}, contentType: ContentType.parse('application/x-www-form-urlencoded')))
          ),
        );
      expect(body.name, 'test');
    });
  });
}
