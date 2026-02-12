import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/utils/config.dart'; // Reuse your Config logic

class AgentsCommand extends Command<int> {

  AgentsCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'claude',
      help: 'Whether to include Claude-specific context.',
    );
  }

  @override
  final String name = 'agents';

  @override
  final String description = 'Generates AGENTS.md and CLAUDE.md and downloads local docs for AI context.';

  final Logger _logger;

  @override
  Future<int> run() async {
    _logger.info('🐦 Setting up Serinus AI Context...');

    // 1. Detect Version
    // We can reuse getProjectConfiguration logic or read pubspec directly
    final config = await getProjectConfiguration(_logger, deps: true);
    final serinusVersion = config.dependencies['serinus'];
    
    // Fallback if version is a path or git dependency, otherwise strict version
    var versionTag = _parseVersion(serinusVersion); 
    _logger.detail('Detected Serinus version: $versionTag');

    // 2. Define Docs to Download
    // You can fetch the file list dynamically from GitHub API or hardcode the structure based on your config.mts sidebar
    final docsMap = {
      'overview': ['modules.md', 'controllers.md', 'routes.md', 'hooks.md', 'middlewares.md', 'providers.md', 'pipes.md', 'metadata.md', 'exception_filters.md'],
      'techniques': ['configuration.md', 'logging.md', 'sse.md', 'task_scheduling.md', 'file_uploads.md', 'mvc.md', 'serve_static.md', 'versioning.md', 'global_prefix.md', 'session.md', 'model_provider.md', 'database.md'],
      'security': ['rate_limiting.md', 'cors.md', 'body_size.md'],
      'openapi': ['index.md', 'advanced_usage.md', 'renderer.md'],
      'websockets': ['gateways.md', 'exception_filters.md', 'pipes.md'],
    };

    final docsDir = Directory(path.join(Directory.current.path, '.serinus-docs'));
    if (!docsDir.existsSync()) {
      docsDir.createSync();
    }

    // 3. Download Files
    var baseUrl = 'https://raw.githubusercontent.com/francescovallone/serinus/$versionTag/.website';
    if (versionTag == 'any' || versionTag == 'main' || versionTag == 'latest') {
      versionTag = 'main';
    }
    if (versionTag != 'main') {
      // Check if versionTag exists on GitHub otherwise fallback to main
      final checkUrl = Uri.parse(baseUrl);
      final checkResponse = await http.get(checkUrl);
      print('Checking URL: $checkUrl - Status: ${checkResponse.statusCode}');
      if (checkResponse.statusCode != 200) {
        _logger.warn('Version $versionTag not found on GitHub, falling back to main branch for docs.');
        versionTag = 'main';
      }
    }
    baseUrl = 'https://raw.githubusercontent.com/francescovallone/serinus/$versionTag/.website';
    final progress = _logger.progress('Downloading documentation...');
    try {
      for (final category in docsMap.keys) {
        final categoryDir = Directory(path.join(docsDir.path, category));
        if (!categoryDir.existsSync()) categoryDir.createSync();

        for (final file in docsMap[category]!) {
           // Handle the path structure in your repo (some are in root, some in subfolders)
           // Based on your file list, many are directly in .website or .website/techniques
           final remotePath = category == 'overview'
               ? file 
               : '$category/$file';
           
           final url = Uri.parse('$baseUrl/$remotePath');
           final response = await http.get(url);
           
           if (response.statusCode == 200) {
             File(path.join(categoryDir.path, file)).writeAsStringSync(response.body);
           }
        }
      }
      progress.complete('Documentation downloaded to .serinus-docs/');
    } catch (e) {
      progress.fail('Failed to download docs: $e');
      return ExitCode.software.code;
    }

    // 4. Generate AGENTS.md
    _generateAgentsMd(docsMap);

    return ExitCode.success.code;
  }

  String _parseVersion(dynamic version) {
    // Logic to strip caret ^ or handle 'any'. Default to 'main' if unknown.
    if (version is String) {
       return version.replaceAll('^', '').replaceAll('~', '');
    }
    return 'main'; 
  }

  void _generateAgentsMd(Map<String, List<String>> docsMap) {
    final buffer = StringBuffer()
    ..write('<!--- SERINUS-AGENTS-MD-START -->')
    // Create the compressed index format Vercel recommends
    ..write('[Serinus Docs Index]|root: ./.serinus-docs')
    ..write('|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for any Serinus related queries.')
    ..write('|If docs missing run `serinus agents` to download the latest version.');
    docsMap.forEach((category, files) {
       // Format: |category:{file1.md,file2.md}
       buffer.write('|$category:{${files.join(',')}}');
    });
    buffer.writeln('<!--- SERINUS-AGENTS-MD-END -->');
    File(path.join(Directory.current.path, 'AGENTS.md')).writeAsStringSync(
      buffer.toString(),
    );

    if (claude) {
      File(path.join(Directory.current.path, 'CLAUDE.md')).writeAsStringSync(
        buffer.toString(),
      );
    }
    
    _logger.success('Generated AGENTS.md');
  }

  bool get claude => argResults?['claude'] as bool? ?? false;
}