import 'dart:io';

import 'package:mockito/mockito.dart';

class FakeRequest extends Fake implements HttpRequest {

  final String data;

  FakeRequest(this.data);
}

void main(){
}