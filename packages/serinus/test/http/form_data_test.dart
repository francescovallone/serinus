import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

void main() async {
  group('$FormData', () {
    group('UrlEncoded', () {
      test(
        '''when create a UrlEncoded FormData with an empty string, then the fields should be an empty map''',
        () {
          final body = FormData.parseUrlEncoded('');
          expect(body.fields, equals({}));
        },
      );
      test(
        '''when create a UrlEncoded FormData with a key-value pair, then the fields should contains the key-value pair''',
        () {
          final body = FormData.parseUrlEncoded('foo=bar');
          expect(body.fields, equals({'foo': 'bar'}));
        },
      );
      test(
        '''when create a UrlEncoded FormData with multiples key-value pairs, then the fields should contains the key-value pairs''',
        () {
          final body = FormData.parseUrlEncoded('foo=bar&bar=foo');
          expect(body.fields, equals({'foo': 'bar', 'bar': 'foo'}));
        },
      );
    });
    group('Multipart', () {
      test(
        'when create a Multipart FormData with fields, then the fields should contain the parsed values',
        () async {
          final stringBuffer = StringBuffer();
          stringBuffer.write('--boundary\r\n');
          stringBuffer.write('Content-Disposition: form-data; name="foo"\r\n');
          stringBuffer.write('\r\n');
          stringBuffer.write('bar\r\n');
          stringBuffer.write('--boundary--\r\n');
          
          final body = await FormData.parseMultipart(
            request: Stream<List<int>>.fromIterable(
              [utf8.encode(stringBuffer.toString())],
            ),
            contentType: 'multipart/form-data; boundary=boundary',
          );
          expect(body.fields, equals({'foo': 'bar'}));
        },
      );
      test(
        'when create a Multipart FormData with fields and the onPart callback is used, then the callback should be called for each part',
        () async {
          final stringBuffer = StringBuffer();
          stringBuffer.write('--boundary\r\n');
          stringBuffer.write('Content-Disposition: form-data; name="foo"\r\n');
          stringBuffer.write('\r\n');
          stringBuffer.write('bar\r\n');
          stringBuffer.write('--boundary--\r\n');
          
          final body = await FormData.parseMultipart(
            request: Stream<List<int>>.fromIterable(
              [utf8.encode(stringBuffer.toString())],
            ),
            onPart: (part) async {
              expect(part, isA<MimeMultipart>());
              final contentDisposition = part.headers['content-disposition'];
              expect(
                contentDisposition,
                equals('form-data; name="foo"'),
              );
            },
            contentType: 'multipart/form-data; boundary=boundary',
          );
          expect(body.fields, equals({'foo': 'bar'}));
        },
      );
    });
  });
}
