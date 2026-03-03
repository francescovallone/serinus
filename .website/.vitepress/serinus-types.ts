import { defineCustomTypes } from '@avesbox/canary'

/**
 * Custom types for Serinus framework documentation.
 * Import this in config.mts and pass to dartInspectTransformer.
 */
export const serinusTypes = defineCustomTypes({
  types: [
    // Core types
    {
      name: 'SerinusFactory',
      description: 'Factory class for creating a Serinus application instance.',
      members: {
        createApplication: { type: 'Future<SerinusApplication>', description: 'Creates a new Serinus application.', parameters: [
          { type: 'Module', name: 'entrypoint', description: 'The root module of the application.', kind: 'named', required: true}
        ], returnType: 'Future<SerinusApplication>'},
      },
      package: 'package:serinus/serinus.dart',
    },
    {
      name: 'SerinusApplication',
      description: 'The main application class that bootstraps and runs the server.',
      members: {
        serve: { type: 'Future<void>', description: 'Starts the HTTP server.', parameters: []},
        use: { type: 'void', description: 'Registers a global middleware or hook.', parameters: [{
          type: 'Processable',
          name: 'processable',
          description: 'The middleware or hook to register.',
          kind: 'positional',
        }] },
      },
      package: 'package:serinus/serinus.dart',
    },
    {
      name: 'serinus',
      kind: 'variable',
      description: 'Top-level variable to create a Serinus application instance.',
      type: 'SerinusFactory',
      package: 'package:serinus/serinus.dart'
    },
    {
      name: 'Module',
      description: 'A class that organizes controllers, providers, and imports.',
      members: {
        controllers: 'List<Controller>',
        providers: 'List<Provider>',
        imports: 'List<Module>',
        exports: 'List<Type>',
      },
      constructors: [
        {
          description: 'Creates a new Module instance.',
          parameters: [
            { type: 'List<Controller>', name: 'controllers', description: 'The controllers to include in this module.', kind: 'named', defaultValue: 'const []' },
            { type: 'List<Provider>', name: 'providers', description: 'The providers to include in this module.', kind: 'named', defaultValue: 'const []' },
            { type: 'List<Module>', name: 'imports', description: 'Other modules to import.', kind: 'named', defaultValue: 'const []' },
            { type: 'List<Type>', name: 'exports', description: 'Types to export from this module.', kind: 'named', defaultValue: 'const []' },
          ]
        }
      ],
      package: 'package:serinus/serinus.dart',
    },
    {
      name: 'Controller',
      description: 'Base class for route controllers that handle HTTP requests.',
      members: {
        path: { type: 'String', description: 'The base path for all routes in this controller.' },
        on: {
          type: 'void',
          typeParameters: ['T', 'B'],
          description: 'Registers a route handler for a specific HTTP method and path.',
          parameters: [
            { type: 'Route', name: 'route', description: 'The route to handle.', kind: 'positional' },
            { type: 'Future<T> Function(RequestContext<B> context)', name: 'handler', description: 'The function that handles the request.', kind: 'positional' },
            { type: 'bool', name: 'shouldValidateMultipart', description: 'Whether to validate multipart requests.', kind: 'named', defaultValue: 'false' },
          ],
        }
      },
      constructors: [
        {
          name: 'Controller',
          description: 'Creates a new Controller instance.',
          parameters: [
            { type: 'String', name: 'path', description: 'The base path for the controller.', kind: 'positional', defaultValue: "''" }
          ]
        }
      ],
      package: 'package:serinus/serinus.dart',
    },
    {
      name: 'Provider',
      description: 'A service that can be injected into controllers and other providers.',
      typeParameters: ['T'],
      package: 'package:serinus/serinus.dart',
    },
    {
      name: 'Route',
      description: 'Represents an HTTP route handled by a controller method.',
      constructors: [
        {
          description: 'Creates a new Route instance.',
          parameters: [
            { type: 'String', name: 'path', description: 'The path for the route.', kind: 'named', required: true },
            { type: 'String', name: 'method', description: 'The HTTP method for the route.', kind: 'named', required: true },
            { type: 'List<Metadata>', name: 'metadata', description: 'Additional metadata for the route.', kind: 'named', defaultValue: 'const []' },
            { type: 'Set<Pipe>', name: 'pipes', description: 'Pipes to apply to the route.', kind: 'named', defaultValue: 'const {}' },
            { type: 'Set<ExceptionFilter>', name: 'exceptionFilters', description: 'Exception filters for the route.', kind: 'named', defaultValue: 'const {}' },
          ],
        },
        {
          name: 'get',
          description: 'Creates a new GET Route instance.',
          parameters: [
            { type: 'String', name: 'path', description: 'The path for the route.', kind: 'positional' },
            { type: 'List<Metadata>', name: 'metadata', description: 'Additional metadata for the route.', kind: 'named', defaultValue: 'const []' },
            { type: 'Set<Pipe>', name: 'pipes', description: 'Pipes to apply to the route.', kind: 'named', defaultValue: 'const {}' },
            { type: 'Set<ExceptionFilter>', name: 'exceptionFilters', description: 'Exception filters for the route.', kind: 'named', defaultValue: 'const {}' },
          ],
          factory: true,
        }
      ],
      package: 'package:serinus/serinus.dart',
    },
    
    // Request/Response
    {
      name: 'Request',
      description: 'Represents an incoming HTTP request.',
      members: {
        method: 'String',
        path: 'String',
        uri: 'Uri',
        headers: 'Map<String, String>',
        body: { type: 'dynamic', description: 'The parsed request body.' },
        query: { type: 'Map<String, String>', description: 'Query parameters from the URL.' },
        params: { type: 'Map<String, String>', description: 'Path parameters from the route.' },
      },
    },
    {
      name: 'Response',
      description: 'Represents an HTTP response to send to the client.',
      members: {
        statusCode: 'int',
        headers: 'Map<String, String>',
        body: 'dynamic',
      },
      staticMembers: {
        json: { type: 'Response', description: 'Creates a JSON response.' },
        text: { type: 'Response', description: 'Creates a plain text response.' },
        html: { type: 'Response', description: 'Creates an HTML response.' },
        redirect: { type: 'Response', description: 'Creates a redirect response.' },
      },
    },
    {
      name: 'RequestContext',
      description: 'Context object available in route handlers.',
      members: {
        request: 'Request',
        params: 'Map<String, String>',
        query: 'Map<String, String>',
        body: 'dynamic',
      },
    },
    
    // Decorators (represented as types for hover)
    {
      name: 'Get',
      description: 'Decorator for HTTP GET routes.',
    },
    {
      name: 'Post',
      description: 'Decorator for HTTP POST routes.',
    },
    {
      name: 'Put',
      description: 'Decorator for HTTP PUT routes.',
    },
    {
      name: 'Delete',
      description: 'Decorator for HTTP DELETE routes.',
    },
    {
      name: 'Patch',
      description: 'Decorator for HTTP PATCH routes.',
    },
    
    // Middleware & Hooks
    {
      name: 'Middleware',
      description: 'Base class for request/response middleware.',
      members: {
        handle: { type: 'Future<void>', description: 'Processes the request before or after the handler.' },
      },
    },
    {
      name: 'Hook',
      description: 'Lifecycle hook for intercepting application events.',
      members: {
        onRequest: 'Future<void>',
        onResponse: 'Future<void>',
      },
    },
    
    // WebSocket
    {
      name: 'WebSocketGateway',
      description: 'Gateway for handling WebSocket connections.',
      members: {
        onConnect: 'Future<void>',
        onDisconnect: 'Future<void>',
        onMessage: 'Future<void>',
      },
    },
    {
      name: 'WebSocketClient',
      description: 'Represents a connected WebSocket client.',
      members: {
        id: 'String',
        send: { type: 'void', description: 'Sends a message to this client.' },
        close: { type: 'Future<void>', description: 'Closes the connection.' },
      },
    },
    {
      name: 'OpenApiModule',
      description: 'Module that provides OpenAPI documentation generation and serving.',
      constructors: [
        {
          name: 'v3',
          description: 'Creates an OpenApiModule for OpenAPI v3 documentation.',
          parameters: [
            { type: 'String', name: 'title', description: 'The title of the API.', kind: 'named', required: true },
            { type: 'String', name: 'version', description: 'The version of the API.', kind: 'named', required: true },
          ],
          factory: true,
        }
      ]
    }
  ],
})
