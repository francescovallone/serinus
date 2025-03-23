
# Parse Schema

To ensure that the request is valid and contains the expected data, Serinus provides the `ParseSchema` class that allows you to parse the query parameters, body, headers, cookies, and path parameters of the request.

The `ParseSchema` follows the [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) principle, so if the parsing fails, the request is not valid and should be rejected.

The `ParseSchema` class has the following properties:

| Property | Description |
| --- | --- |
| `query` | A validator that will be used to parse the query parameters. |
| `body` | A validator that will be used to parse the body of the request. |
| `headers` | A validator that will be used to parse the headers of the request. |
| `session` | A validator that will be used to parse the cookies of the request. |
| `params` | A validator that will be used to parse the path parameters of the request. |
| `error` | Custom exception that will be returned if the parsing fails. |

All the properties are optional, so you can use only the ones you need. But remember that all the properties except the body must accept and return a `Map<String, dynamic>`.
The body property must accept and return a `dynamic` type.
The `ParseSchema` class is abstract, so you can create your own implementation of the class and override the `tryParse` method to implement your own parsing logic.

Or you can use one of the provided implementations:

| Implementation | Description | Link |
| --- | --- | --- |
| `AcanthisParseSchema` | Official implementation of the `ParseSchema` class that uses the `Acanthis` library to parse the request. | |
