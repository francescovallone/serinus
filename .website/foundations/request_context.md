# Request Context

The `RequestContext` is a class that holds the request information and provides a way to interact with the request. 

Using the `RequestContext` ensures that the information is consistent and that the request is processed correctly.

## Properties

The `RequestContext` class has the following properties:

| Property | Description |
| --- | --- |
| **request** | The `Request` object that holds the request information. |
| **providers** | A map of `Provider`s that can be used to inject dependencies into the route handler. |
| **headers** | A map of headers that were sent in the request. |
| **params** | A map of path parameters that were sent in the request. |
| **query** | A map of query parameters that were sent in the request. |
| **body** | The body of the request. [Read more](body) |
| **path** | The path of the request that triggered the handler |
| **res** | Utility class to interact with the response headers and statusCode. |

::: warning
The statusCode value must be between 100 and 999.
:::

## Methods

The `RequestContext` class has the following methods:

| Method | Description |
| --- | --- |
| **use** | Returns the `Provider` of the requested type - e.g. `use<TestProvider>()` |
| **canUse** | Checks if the `Provider` of the requested type is available - e.g. `canUse<TestProvider>()` |
| **stat** | Returns the `Metadata` value of the requested name - e.g. `stat('Metadata')`|
| **canStat** | Checks if the requested `Metadata` is available in the context - e.g. `canStat('Metadata')` |
| **stream** | Starts a stream response - e.g. `stream()` |
