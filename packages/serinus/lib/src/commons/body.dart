import 'dart:io';

import '../commons/form_data.dart';

class Body {

  final FormData? formData;
  final ContentType contentType;
  final String? text;
  final List<int>? bytes;
  final Map<String, dynamic>? json;

  Body(
    this.contentType,
    {
      this.formData,
      this.text,
      this.bytes,
      this.json
    }
  );
  
}