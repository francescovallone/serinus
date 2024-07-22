
# Parse Schema

To ensure that the request is valid and contains the expected data, Serinus provides the `ParseSchema` class that allows you to parse the query parameters, body, headers, cookies, and path parameters of the request.

The `ParseSchema` follows the [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) principle, so if the parsing fails, the request is not valid and should be rejected.

::: info
Serinus uses [Acanthis](https://pub.dev/packages/acanthis) under the hood to take care of the parse and validate process. 🐤
:::

The `ParseSchema` class has the following properties:

- `query`: A schema that will be used to parse the query parameters.
- `body`: A schema that will be used to parse the body of the request.
- `headers`: A schema that will be used to parse the headers of the request.
- `session`: A schema that will be used to parse the cookies of the request.
- `params`: A schema that will be used to parse the path parameters of the request.
- `error`: Custom exception that will be returned if the parsing fails.

All the schemas are optional and you can use them in any combination and the `body` schema is not an object schema, so you can use any schema that you want.