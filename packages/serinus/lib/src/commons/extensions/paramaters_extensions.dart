import 'dart:mirrors';

extension CheckDuplicateExtensions on List<ParameterMirror> {
  
  bool hasDuplicatesByName(){
    final metadata = map(
      (e) => e.metadata
    );
    if(metadata.isEmpty){
      return false;
    }
    final names = metadata.reduce(
      (value, element) => [
        ...value,
        ...element
      ]
    ).map(
      (e) => e.getField(Symbol('name'))
    );
    final uniqueNames = names.toSet();
    return names.length != uniqueNames.length;
  }

  bool checkDuplicatesByType(){
    return this.map(
      (e) => e.metadata
    ).any(
      (element) => element.length > 1
    );
  }

}