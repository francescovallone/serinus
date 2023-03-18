import 'dart:io';

class FormData{

  final Map<String, dynamic> _fields;
  final Map<String, UploadedFile> _files;

  const FormData({
    Map<String, dynamic> fields = const {},
    Map<String, UploadedFile> files = const {}
  }) : _fields = fields, _files = files;

  Map<String, dynamic> get fields => Map.unmodifiable(_fields);
  Map<String, UploadedFile> get files => Map.unmodifiable(_files);

}


class UploadedFile{

  final ContentType _contentType;
  final Stream<List<int>> _stream;
  final String name;

  const UploadedFile(
    this._stream,
    this._contentType,
    this.name
  );

}

