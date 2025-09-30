import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:mustachex/mustachex.dart';

class MustacheViewEngine extends ViewEngine {
  
  const MustacheViewEngine({
    super.viewFolder
  });

  @override
  Future<String> render(View view) async {
    final processor = MustachexProcessor(
      initialVariables: view.variables
    );
    if(view.fromFile) {
      final template = File('${Directory.current.path}/$viewFolder/${view.template}.mustache');
      final exists = await template.exists();
      if(exists){
        final content = await template.readAsString();
        final processed = await processor.process(content);
        return processed;
      }
      return await _notFoundView(view.template);
    }
    return await processor.process(view.template);
  }

  Future<String> _notFoundView(String view) async {
    final processor = MustachexProcessor(
      initialVariables: {'view': view}
    );
    return await processor.process('View ${view} not found');
  }
  
}