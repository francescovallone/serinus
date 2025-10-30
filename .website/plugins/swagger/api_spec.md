# Api Specification

## Introduction

The `serinus_openapi` plugins provides a way to generate an OpenAPI Specification document for your Serinus application and do so creating two fundamentals classes:

- `ApiRoute` - A route which exposes a ApiSpec property to define the route's OpenAPI Specification.
- `ApiSpec` - The class that represents the OpenAPI Specification document.

## ApiRoute

The `ApiRoute` class is a route which exposes a ApiSpec property to define the route's OpenAPI Specification.

### Properties

- `path` - The path of the route. (required)
- `method` - The method of the route. (default: `GET`)
- `apiSpec` - The OpenAPI Specification (`ApiSpec`) for the route. (required)
- `queryParameters` - The query parameters for the route. (optional, if defined they will be integrated into the route's parameters list in the OpenAPI Specification)

### Short Versions of the ApiRoute

Like the `Route` class, the `ApiRoute` class has short versions of the class to make it easier to define the routes.

```dart [Short Version GET.dart]
ApiRoute.get(
    path: '/users',
    response: ApiResponse(
        code: HttpStatus.ok,
        content: ResponseObject(
            description: 'Success response',
            content: [
                MediaObject(
                    encoding: ContentType.text,
                    schema: SchemaObject(
                        type: SchemaType.ref,
                        value: 'responses/SuccessResponse'
                    )
                )
            ]
        )
    ),
    queryParameters: {
        'name': String,
        'age': int,
    }
)
```

The short versions of the class are:

- `ApiRoute.get`
- `ApiRoute.post`
- `ApiRoute.put`
- `ApiRoute.delete`
- `ApiRoute.patch`

## ApiSpec

The `ApiSpec` class is used to define the OpenAPI Specification document for your application.

### Properties

- `tags` - The tags specific to the route. (optional)
- `responses` - The responses for the route. (required)
- `requestBody` - The request body for the route. (optional)
- `operationId` - The operation id for the route. (optional)
- `summary` - The summary of the route. (optional)
- `description` - The description of the route. (optional)
- `parameters` - The parameters for the route. (optional)

### Example

```dart
class HelloWorldRoute extends ApiRoute {

  HelloWorldRoute({super.queryParameters}) : super(
    path: '/',
    apiSpec: ApiSpec(
      parameters: [
        ParameterObject(
          name: 'name',
          in_: SpecParameterType.query,
          required: false,
        )
      ],
      responses: [
        ApiResponse(
          code: HttpStatus.ok,
          content: ResponseObject(
            description: 'Success response',
            content: [
              MediaObject(
                encoding: ContentType.text,
                schema: SchemaObject(
                  type: SchemaType.ref,
                  value: 'responses/SuccessResponse'
                )
              )
            ]
          )
        ),
      ]
    )
  );
}
```

In the example above, we are defining a route that has a query parameter `name` and a response with a schema reference to `responses/SuccessResponse`.

This route will be mapped inside the OpenAPI Specification document as following:

```yaml
/: 
    get: 
        tags: 
            - 'AppController'
        responses: 
            200: 
            description: 'Success response'
            headers: {}
            content: 
                text/plain: 
                schema: 
                    $ref: '#/components/responses/SuccessResponse'
    parameters: 
        - name: 'name'
            in: 'query'
            schema: {}
            required: false
            deprecated: false
```

As you can see the Route contains also a `tags` property that is used to group the routes in the OpenAPI Specification document.
The `tags` property is equal to the name of the controller where the route is defined.
