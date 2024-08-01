# Request Lifecycle

The request lifecycle is the process that a request goes through in order to be handled by the server. This process is the same for all requests, regardless of the type of request or the route that it is sent to.

The following image summarizes the request lifecycle in Serinus:

<img src="/request-lifecycle.png" alt="Request Lifecycle" style="width: 100%;">

The request lifecycle consists of the following steps:

| Step | Description |
| ---- | ----------- |
| **Request** | The client sends a request to the server. |
| **onRequest** | Serinus receives the request and execute all the onRequest hooks. |
| **Routing** | Serinus determines which route to use based on the request URL. |
| **tranform** | Serinus executes the local transform hook. |
| **parse** | Serinus executes the ParseSchema of the route if available. |
| **Middlewares** | Serinus executes the middlewares for the route. |
| **beforeHandle** | Serinus executes the global beforeHandle hook and then the local one. |
| **Handler** | Serinus executes the handler for the route. |
| **afterHandle** | Serinus executes the local afterHandle hook and then the global one. |
| **onResponse** | Serinus executes the onResponse hooks. |
| **Response** | Serinus sends the response back to the client. |
