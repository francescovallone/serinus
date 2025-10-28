# Microservices

In addition to building monolithic applications, Serinus natively supports the development of microservices architectures. This allows developers to create small, independent services that can communicate with each other, enabling scalability, flexibility, and easier maintenance.

In Serinus microservices are fundamentally applications that uses a different **transport layer** than HTTP.

## Getting started

To instantiate a microservice application, you can use the `createMicroservice` method from the `serinus` package. This method allows you to create a microservice application with a specified transport layer.

```dart