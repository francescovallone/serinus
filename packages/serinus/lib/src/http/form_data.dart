import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../exceptions/exceptions.dart';
import '../mixins/object_mixins.dart';

/// The class FormData is used to parse multipart/form-data and application/x-www-form-urlencoded
class FormData {
  final Map<String, dynamic> _fields;
  final Map<String, UploadedFile> _files;

  /// The [FormData] constructor is used to create a [FormData] object
  const FormData(
      {Map<String, dynamic> fields = const {},
      Map<String, UploadedFile> files = const {}})
      : _fields = fields,
        _files = files;

  /// This method is used to get the values of the form data
  Map<String, dynamic> get values =>
      Map.unmodifiable({'fields': fields, 'files': files});

  /// This method is used to get the fields of the form data
  ///
  /// The fields are the key-value pairs of the form data
  Map<String, dynamic> get fields => Map.unmodifiable(_fields);

  /// This method is used to get the files of the form data
  Map<String, UploadedFile> get files => Map.unmodifiable(_files);

  /// This method is used to get the length of the form data
  ///
  /// The length is the total length of the form data
  ///
  /// The length is calculated by getting the length of the fields and the files
  int get length {
    return jsonEncode(fields).length +
        _files.values.fold(0, (p, e) => p + e._data.length);
  }

  /// This method is used to parse the request body as a [FormData] if the content type is multipart/form-data
  static Future<FormData> parseMultipart({required HttpRequest request}) async {
    try {
      final mediaType = MediaType.parse(
          request.headers[HttpHeaders.contentTypeHeader]!.join(';'));
      final boundary = mediaType.parameters['boundary'];
      final parts = _getMultiparts(request, boundary);
      RegExp regex = RegExp('([a-zA-Z0-9-_]+)="(.*?)"');
      final fields = <String, dynamic>{};
      final files = <String, UploadedFile>{};
      await for (MimeMultipart part in parts) {
        final contentDisposition = part.headers['content-disposition'];
        if (contentDisposition == null ||
            !contentDisposition.startsWith('form-data;')) {
          continue;
        }
        final values = regex
            .allMatches(contentDisposition)
            .fold(<String, String>{}, (map, match) {
          return map..[match.group(1)!] = match.group(2)!;
        });

        final name = values['name']!;
        final fileName = values['filename'];

        if (fileName != null) {
          files[name] = UploadedFile(
            part,
            ContentType.parse(part.headers['content-type'] ?? 'text/plain'),
            fileName,
          );
          await files[name]!.read();
        } else {
          final bytes =
              (await part.toList()).fold(<int>[], (p, e) => p..addAll(e));
          fields[name] = utf8.decode(bytes);
        }
      }
      return FormData(fields: fields, files: files);
    } catch (_) {
      throw NotAcceptableException();
    }
  }

  /// This method is used to parse the request body as a [FormData] if the content type is application/x-www-form-urlencoded
  factory FormData.parseUrlEncoded(String body) {
    return FormData(fields: Uri.splitQueryString(body), files: {});
  }

  static Stream<MimeMultipart> _getMultiparts(
      HttpRequest request, String? boundary) {
    if (boundary == null) {
      throw StateError('Not a multipart request.');
    }

    return MimeMultipartTransformer(boundary).bind(request);
  }
}

/// The class [UploadedFile] is used to represent a file uploaded by the user
/// It is used to parse the file and store it in a string
/// The string can be accessed by calling the [toString] method
/// The [readAsString] method is used to parse the file and store it in the string
/// The [stream] property is used to get the stream of the file
/// The [contentType] property is used to get the content type of the file
/// The [name] property is used to get the name of the file
class UploadedFile with JsonObject {
  /// The content type of the file
  final ContentType contentType;

  /// The stream of bytes of the file
  final Stream<List<int>> stream;

  /// The name of the file
  final String name;

  final List<int> _data = [];

  /// The [buffer] property is used to get the bytes buffer of the file
  List<int> get buffer => _data;

  /// The [data] property is used to get the strigified data of the file
  String get data => utf8.decode(_data);

  /// The [UploadedFile] constructor is used to create a [UploadedFile] object
  UploadedFile(this.stream, this.contentType, this.name);

  /// This method is used to read the file as a string
  Future<void> read() async {
    await for (final part in stream) {
      _data.addAll(part);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contentType': contentType.toString(),
      'buffer': buffer,
      'data': data
    };
  }
}
