import 'dart:mirrors';

extension CheckDuplicateExtensions on List<ParameterMirror> {
  
  bool hasDuplicatesByName({bool Function(InstanceMirror)? additionalCheck}){
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
    ).where((element){
      if(additionalCheck == null){
        return true;
      }
      return additionalCheck.call(element);
    }).map(
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