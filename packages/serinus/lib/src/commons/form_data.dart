import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:serinus/serinus.dart';

class FormData{

  final Map<String, dynamic> _fields;
  final Map<String, UploadedFile> _files;

  const FormData({
    Map<String, dynamic> fields = const {},
    Map<String, UploadedFile> files = const {}
  }) : _fields = fields, _files = files;

  Map<String, dynamic> get values => Map.unmodifiable({
    "fields": fields,
    "files": files
  });
  Map<String, dynamic> get fields => Map.unmodifiable(_fields);
  Map<String, UploadedFile> get files => Map.unmodifiable(_files);

  static Future<FormData> parseMultipart({
    required HttpRequest request
  }) async {
    try{
      final mediaType = MediaType.parse(request.headers[HttpHeaders.contentTypeHeader]!.join(';'));
      final boundary = mediaType.parameters['boundary'];
      final parts = _getMultiparts(request, boundary);
      RegExp regex = RegExp('([a-zA-Z0-9-_]+)="(.*?)"');
      final fields = <String, dynamic>{};
      final files = <String, UploadedFile>{};
      await for (MimeMultipart part in parts){
        final contentDisposition = part.headers['content-disposition'];
        if (contentDisposition == null) continue;
        if (!contentDisposition.startsWith('form-data;')) continue;

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
          await files[name]!.readAsString();
        } else {
          final bytes = (await part.toList()).fold(<int>[], (p, e) => p..addAll(e));
          fields[name] = utf8.decode(bytes);
        }
      }
      
      return FormData(fields: fields, files: files);
    }catch(e){
      print(e);
      throw NotAcceptableException();
    }
  }

  static FormData parseUrlEncoded(String body) {
    return FormData(fields: Uri.splitQueryString(body), files: {});
  }

  static Stream<MimeMultipart> _getMultiparts(HttpRequest request, String? boundary){
    if (boundary == null) {
      throw StateError('Not a multipart request.');
    }

    return MimeMultipartTransformer(boundary)
        .bind(request);
  }

}
class UploadedFile{

  final ContentType contentType;
  final Stream<List<int>> stream;
  final String name;
  String _data = "";

  UploadedFile(
    this.stream,
    this.contentType,
    this.name
  );

  Future<void> readAsString() async {
    List<String> data = [];
    await for(final part in stream){
      data.add(String.fromCharCodes(part));
    }
    _data = data.join('');
  }

  @override
  String toString() {
    return _data;
  }

}

class Multipart extends MimeMultipart{

  final MimeMultipart _inner;

  Multipart(this._inner);

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _inner.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }
  
  @override
  // TODO: implement headers
  Map<String, String> get headers => throw UnimplementedError();
  
}