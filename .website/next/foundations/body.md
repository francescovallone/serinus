# Body

Serinus handles the body of a request in a very simple way using the `Body` class. The `Body` exposes the properties to read the body of the request as a `String`, `List<int>`, `JsonBody` or `FormData`. The `Body` class is used in the `Request` class to read the body of the request.

## Body Types

| Property | Description |
|----------|-------------|
| `text` | The body of the request as a `String`. |
| `bytes` | The body of the request as a `List<int>`. |
| `json` | The body of the request as a `JsonBody`. |
| `formData` | The body of the request as a `FormData`. |

::: info
The `JsonBody` class is a sealed class family to exposes both the `JsonBodyObject` and the `JsonList` types representing a JSON object and a list of JSON objects respectively. 

To check if a `JsonBody` is a `JsonBodyObject` or a `JsonList` you can check the `multiple` property of the `JsonBody` object. If it is `true` then the `JsonBody` is a `JsonList`, otherwise it is a `JsonBodyObject`.
:::

## Methods

It also exposes some useful methods like:

| Method | Description |
|--------|-------------|
| `value` | The value of the body as a `dynamic`. |
| `length` | The length of the body as an `int`. |