import 'dart:io';
import 'package:mime/mime.dart';
import 'package:serinus/serinus.dart';

/// The [ServeStaticController] class is used to create a new instance of the serve static controller.
///
/// This controller is used to serve static files from the current directory.
class ServeStaticController extends Controller {
  /// The [extensions] property contains the extensions whitelist of the controller.
  final List<String> exclude;

  final List<String> extensions;

  final String routePath;

  final List<String> index;

  final bool redirect;

  /// The [ServeStaticController] constructor is used to create a new instance of the [ServeStaticController] class.
  ServeStaticController({
    required super.path,
    required this.routePath,
    this.exclude = const [],
    this.extensions = const [],
    this.index = const ['index.html'],
    this.redirect = true,
  }) {
    on(Route.get('/'), _serveFile);
    on(Route.get(routePath), _serveFile);
  }

  Future<File> _serveFile(RequestContext context) async {
    final path = context.request.path;
    if(exclude.contains(path.replaceAll(super.path, ''))) {
      throw ForbiddenException(
        message: 'The path $path is not available to be served'
      );
    }
    Directory current = Directory.current;
    final file = File('${current.path}/$path');
    final directory = Directory('${current.path}/$path');
    final fileExists = file.existsSync();
    final directoryExists = directory.existsSync();
    if(fileExists && !directoryExists) {
      context.res.contentType = ContentType.parse(lookupMimeType(file.absolute.path) ?? 'text/plain');
      return file;
    }
    if(!fileExists && directoryExists) {
      for(final i in index) {
        final indexFile = File('${current.path}/$path$i');
        if(indexFile.existsSync() && redirect) {
          context.res.contentType = ContentType.parse(lookupMimeType(indexFile.absolute.path) ?? 'text/plain');
          return indexFile;
        }
      }
      throw BadRequestException(
        message: 'The chosen path is a directory and none of the following files is available in the directory. [${index.join(',')}]'
      );
    }
    if(!fileExists && !directoryExists) {
      for(final ext in extensions) {
        final extension = file.absolute.path.split('.').lastOrNull;
        var newExtensionPath = file.absolute.path;
        if(extension == null) {
          newExtensionPath = '${file.absolute.path.substring(file.absolute.path.length - 1)}.$ext';
        } else {
          newExtensionPath = file.absolute.path.replaceAll(extension, ext);
        }
        final newFile = File(newExtensionPath);
        if(newFile.existsSync()) {
          context.res.contentType = ContentType.parse(lookupMimeType(newFile.absolute.path) ?? 'text/plain');
          return newFile;
        }
      }
    }
    throw NotFoundException(
      message: 'The file or directory $path does not exists'
    );
  }
}
