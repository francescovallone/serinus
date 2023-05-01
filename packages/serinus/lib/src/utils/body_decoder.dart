import 'dart:io';

bool isUrlEncodedFormData(ContentType contentType){
  return contentType.subType == "x-www-form-urlencoded" ;
}

bool isMultipartFormData(ContentType contentType){
  return contentType.mimeType == "multipart/form-data";
}