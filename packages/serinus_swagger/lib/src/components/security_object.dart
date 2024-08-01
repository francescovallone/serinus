import '../api_spec.dart';
import 'component.dart';

/// Represents a security object in the OpenAPI specification.
final class SecurityObject extends ComponentValue {
  /// The [type] property contains the type of the security object.
  final SecurityType type;

  /// The [scheme] property contains the scheme of the security object.
  final SecurityScheme? scheme;

  /// The [bearerFormat] property contains the bearer format of the security object.
  final String? bearerFormat;

  /// The [inType] property contains the in type of the security object.
  final SpecParameterType? inType;

  /// The [name] property contains the name of the security object.
  final String? name;

  /// The [isDefault] property contains the default status of the security object.
  final bool isDefault;

  /// The [flows] property contains the flows of the security object.
  final FlowsObject? flows;

  /// The [openIdConnectUrl] property contains the openIdConnectUrl of the security object.
  final String? openIdConnectUrl;

  /// The [SecurityObject] constructor is used to create a new instance of the [SecurityObject] class.
  SecurityObject({
    required this.type,
    this.scheme,
    this.bearerFormat,
    this.inType,
    this.name,
    this.isDefault = true,
    this.flows,
    this.openIdConnectUrl,
  }) {
    if (type == SecurityType.apiKey && inType == null) {
      throw Exception('inType must be provided for apiKey type');
    }
    if (type == SecurityType.apiKey && name == null) {
      throw Exception('name must be provided for apiKey type');
    }
    if (type == SecurityType.apiKey &&
        ![
          SpecParameterType.header,
          SpecParameterType.cookie,
          SpecParameterType.query
        ].contains(inType)) {
      throw Exception('inType must be header, cookie or query for apiKey type');
    }
    if (type == SecurityType.http && scheme == null) {
      throw Exception('scheme must be provided for http type');
    }
    if (type == SecurityType.http &&
        scheme == SecurityScheme.bearer &&
        bearerFormat == null) {
      throw Exception('bearerFormat must be provided for bearer scheme');
    }
    if (type == SecurityType.oauth2 && flows == null) {
      throw Exception('flows must be provided for oauth2 type');
    }
    if (type == SecurityType.openIdConnect && openIdConnectUrl == null) {
      throw Exception(
          'openIdConnectUrl must be provided for openIdConnect type');
    }
  }

  /// The [setAsDefault] method is used to set the default status of the security object.
  SecurityObject setAsDefault({
    bool isDefault = true,
  }) {
    return SecurityObject(
      type: type,
      scheme: scheme,
      bearerFormat: bearerFormat,
      inType: inType,
      name: name,
      isDefault: isDefault,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> schemaObj = {
      'type': type.toString().split('.').last,
    };
    if (type == SecurityType.apiKey) {
      schemaObj['in'] = inType.toString().split('.').last;
      schemaObj['name'] = name;
    }
    if (type == SecurityType.http) {
      schemaObj['scheme'] = scheme.toString().split('.').last;
      if (scheme == SecurityScheme.bearer) {
        schemaObj['bearerFormat'] = bearerFormat;
      }
    }
    if (flows != null) {
      schemaObj['flows'] = flows!.toJson();
    }
    if (openIdConnectUrl != null) {
      schemaObj['openIdConnectUrl'] = openIdConnectUrl;
    }
    return schemaObj;
  }
}

/// The [SecurityType] enum is used to define the type of security.
enum SecurityType {
  apiKey,
  http,
  oauth2,
  openIdConnect,
}

/// The [SecurityScheme] enum is used to define the scheme of security.
enum SecurityScheme {
  bearer,
  basic,
}

/// Represents a flows object in the OpenAPI specification.
class FlowsObject {
  /// The [implicit] property contains the implicit flow object.
  final ImplicitFlowObject? implicit;

  /// The [password] property contains the password flow object.
  final CredentialsFlowObject? password;

  /// The [clientCredentials] property contains the client credentials flow object.
  final CredentialsFlowObject? clientCredentials;

  /// The [authorizationCode] property contains the authorization code flow object.
  final AuthorizationCodeFlowObject? authorizationCode;

  /// The [FlowsObject] constructor is used to create a new instance of the [FlowsObject] class.
  FlowsObject({
    this.implicit,
    this.password,
    this.clientCredentials,
    this.authorizationCode,
  });

  /// The [toJson] method is used to convert the object into a JSON object.
  Map<String, dynamic> toJson() {
    return {
      if (implicit != null) 'implicit': implicit!.toJson(),
      if (password != null) 'password': password!.toJson(),
      if (clientCredentials != null)
        'clientCredentials': clientCredentials!.toJson(),
      if (authorizationCode != null)
        'authorizationCode': authorizationCode!.toJson(),
    };
  }
}

/// Represents an implicit flow object in the OpenAPI specification.
final class ImplicitFlowObject {
  /// The [authorizationUrl] property contains the authorization URL of the implicit flow object.
  final String? authorizationUrl;

  /// The [refreshUrl] property contains the refresh URL of the implicit flow object.
  final String refreshUrl;

  /// The [scopes] property contains the scopes of the implicit flow object.
  final Map<String, String> scopes;

  /// The [ImplicitFlowObject] constructor is used to create a new instance of the [ImplicitFlowObject] class.
  ImplicitFlowObject({
    this.authorizationUrl,
    this.refreshUrl = '',
    this.scopes = const {},
  });

  /// The [toJson] method is used to convert the object into a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'authorizationUrl': authorizationUrl,
      if (refreshUrl.isNotEmpty) 'refreshUrl': refreshUrl,
      'scopes': scopes,
    };
  }
}

/// Represents an authorization code flow object in the OpenAPI specification.
final class AuthorizationCodeFlowObject {
  /// The [authorizationUrl] property contains the authorization URL of the authorization code flow object.
  final String authorizationUrl;

  /// The [tokenUrl] property contains the token URL of the authorization code flow object.
  final String tokenUrl;

  /// The [refreshUrl] property contains the refresh URL of the authorization code flow object.
  final String refreshUrl;

  /// The [scopes] property contains the scopes of the authorization code flow object.
  final Map<String, String> scopes;

  /// The [AuthorizationCodeFlowObject] constructor is used to create a new instance of the [AuthorizationCodeFlowObject] class.
  AuthorizationCodeFlowObject({
    required this.authorizationUrl,
    required this.tokenUrl,
    this.refreshUrl = '',
    this.scopes = const {},
  });

  /// The [toJson] method is used to convert the object into a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'authorizationUrl': authorizationUrl,
      'tokenUrl': tokenUrl,
      if (refreshUrl.isNotEmpty) 'refreshUrl': refreshUrl,
      'scopes': scopes,
    };
  }
}

/// Represents a credentials flow object in the OpenAPI specification.
final class CredentialsFlowObject {
  /// The [tokenUrl] property contains the token URL of the credentials flow object.
  final String tokenUrl;

  /// The [refreshUrl] property contains the refresh URL of the credentials flow object.
  final String refreshUrl;

  /// The [scopes] property contains the scopes of the credentials flow object.
  final Map<String, String> scopes;

  /// The [CredentialsFlowObject] constructor is used to create a new instance of the [CredentialsFlowObject] class.
  CredentialsFlowObject({
    required this.tokenUrl,
    this.refreshUrl = '',
    this.scopes = const {},
  });

  /// The [toJson] method is used to convert the object into a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'tokenUrl': tokenUrl,
      if (refreshUrl.isNotEmpty) 'refreshUrl': refreshUrl,
      'scopes': scopes,
    };
  }
}
