import 'api_spec.dart';
import 'components/components.dart';

/// The [DocumentSpecification] class contains the needed information to generate the Swagger document.
class DocumentSpecification {
  /// The [title] property contains the title of the document.
  final String title;

  /// The [version] property contains the version of the document.
  final String version;

  /// The [description] property contains the description of the document.
  final String description;

  /// The [termsOfService] property contains the terms of service of the document.
  final String? termsOfService;

  /// The [securitySchema] property contains the security schema of the document.
  Component<SecurityObject>? securitySchema;

  /// The [contact] property contains the contact information of the document.
  final ContactObject? contact;

  /// The [license] property contains the license information of the document.
  final LicenseObject? license;

  /// The [DocumentSpecification] constructor is used to create a new instance of the [DocumentSpecification] class.
  DocumentSpecification({
    required this.title,
    required this.version,
    this.description = '',
    this.contact,
    this.license,
    this.termsOfService,
  });

  /// The [addSecurity] method is used to add a security schema.
  void addSecurity(Component<SecurityObject> schema) {
    securitySchema =
        Component(name: schema.name, value: schema.value?.setAsDefault());
  }

  /// The [addBasicAuth] method is used to add a basic authentication.
  void addBasicAuth() {
    securitySchema = Component(
        name: 'basicAuth',
        value: SecurityObject(
          type: SecurityType.http,
          scheme: SecurityScheme.basic,
        ).setAsDefault());
  }

  /// The [addApiKeyAuth] method is used to add an API key authentication.
  void addApiKeyAuth({
    required String name,
    required SpecParameterType inType,
  }) {
    securitySchema = Component(
        name: 'apiKeyAuth',
        value: SecurityObject(
          type: SecurityType.apiKey,
          name: name,
          inType: inType,
        ).setAsDefault());
  }

  /// The [addOAuth2Auth] method is used to add an OAuth2 authentication.
  void addOAuth2Auth({
    required FlowsObject flows,
  }) {
    securitySchema = Component(
        name: 'oauth2Auth',
        value: SecurityObject(
          type: SecurityType.oauth2,
          flows: flows,
        ).setAsDefault());
  }

  /// The [addOpenIdConnectAuth] method is used to add an OpenID Connect authentication.
  void addOpenIdConnectAuth({
    required String openIdConnectUrl,
  }) {
    securitySchema = Component(
        name: 'openIdConnectAuth',
        value: SecurityObject(
          type: SecurityType.openIdConnect,
          openIdConnectUrl: openIdConnectUrl,
        ).setAsDefault());
  }

  /// The [addBearerAuth] method is used to add a bearer authentication.
  void addBearerAuth({
    required String bearerFormat,
  }) {
    securitySchema = Component(
        name: 'bearerAuth',
        value: SecurityObject(
          type: SecurityType.http,
          scheme: SecurityScheme.bearer,
          bearerFormat: bearerFormat,
        ).setAsDefault());
  }

  /// The [toJson] method is used to convert the [DocumentSpecification] to a [Map<String, dynamic>].
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'version': version,
      'description': description,
      if (termsOfService != null) 'termsOfService': termsOfService,
      if (contact != null)
        'contact': {
          'name': contact!.name,
          'url': contact!.url,
          'email': contact!.email,
        },
      if (license != null) 'license': license?.toJson()
    };
  }
}

/// The [ContactObject] class contains the contact information.
final class ContactObject {
  /// The [name] property contains the name of the contact.
  final String name;

  /// The [url] property contains the URL of the contact.
  final String url;

  /// The [email] property contains the email of the contact.
  final String email;

  /// The [ContactObject] constructor is used to create a new instance of the [ContactObject] class.
  ContactObject({
    required this.name,
    required this.url,
    required this.email,
  });
}

/// The [LicenseObject] class contains the license information.
final class LicenseObject {
  /// The [name] property contains the name of the license.
  final String name;

  /// The [identifier] property contains the identifier of the license.
  final String? identifier;

  /// The [url] property contains the URL of the license.
  final String url;

  /// The [LicenseObject] constructor is used to create a new instance of the [LicenseObject] class.
  LicenseObject({
    required this.name,
    this.identifier,
    required this.url,
  });

  /// The [toJson] method is used to convert the [LicenseObject] to a [Map<String, dynamic>].
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (identifier != null) 'identifier': identifier,
      'url': url,
    };
  }
}
