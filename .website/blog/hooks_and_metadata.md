---
title: How Hooks and Metadata can improve your Serinus application
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: How Hooks and Metadata can improve your Serinus application

    - - meta
      - name: 'description'
        content: Hooks and Metadata are two powerful tools that can improve your Serinus application. Learn how to use them in this article.

    - - meta
      - property: 'og:description'
        content: Hooks and Metadata are two powerful tools that can improve your Serinus application. Learn how to use them in this article.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/hooks_and_metadata/hooks_and_metadata.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/hooks_and_metadata/hooks_and_metadata.webp
---
<script setup>
	import BlogPage from '../components/blog_page.vue'
</script>

<BlogPage
	title="How Hooks and Metadata can improve your Serinus application"
	src="/blog/hooks_and_metadata/hooks_and_metadata.webp"
	alt="How Hooks and Metadata can improve your Serinus application"
	author="Francesco Vallone"
	date="28 Jan 2025"
  :tags="['techniques']"
	shadow
>
Serinus makes use of two powerful tools to specialize the behavior of your application: Hooks and Metadata. These two core concepts are perfect to handle different kind of situations in your application, from Authentication to Authorization, from Caching to Rate Limiting.
But first, let's understand what are Hooks and Metadata and how they can be used in your application.

## Hooks

Hooks are elements that can be used to "hook" to the request lifecycle. They can be used to execute code before or after a specific event, for example you can check for the Authorization of the request before the handler is executed or you can log the request after the handler is executed.

In Serinus there are 4 types of Hooks that can be used:
- **OnRequest**: This hook is executed when the request is received by the server.
- **OnResponse**: This hook is executed when the response is sent to the client.
- **BeforeHandle**: This hook is executed before the handler is executed.
- **AfterHandle**: This hook is executed after the handler is executed.

To specialize an hook with one of the 4 types you can extend your class with the `Hook` class and the `OnRequestResponse`, `OnBeforeHandle` or `OnAfterHandle` mixin.

```dart
class MyHook extends Hook with OnBeforeHandle {
  @override
  Future<void> onBeforeHandle(RequestContext request) async {
    // Your code here
  }
}
```

## Metadata

Metadata is a way to specialize the behavior. It can be used to provide contextualized values or raw values to the request lifecycle. For example you can use Metadata to provide the user that is making the request to the handler or you can use Metadata to provide the rate limit of the request.

In Serinus Metadata can be used in 2 different ways:
- **Controller Metadata**: This Metadata is executed before the handler of the controller is executed.
- **Route Metadata**: This Metadata is executed before the handler of the route is executed.

Also Metadata can be initialized using the `BaseContext` abstract class by extending.

```dart
class AppController extends Controller {
  
    @override
    List<Metadata> get metadata => [
        Metadata(
            name: 'ControllerMetadata',
            value: 'ControllerMetadataValue',
        ),
    ];

    AppController(): super(path: '/') {
        on(
            Route.get(
                '/', 
                metadata: [
                    ContextualizedMetadata(
                        name: 'RouteMetadata',
                        value: (context) async => context.request.method,
                    ),
                ]
            ), 
            (RequestContext context) async {
                return context.stat('RouteMetadata'); // Should return the method of the request
            }
        );
    }
  
}
```

## How to use them together

Hooks and Metadata can be used together to provide a more specialized behavior to your application. For example you can use a Hook to check the Authorization of the request and then use Metadata to provide the user to the handler. Or you can use the Metadata to tell the hook not to check the Authorization of the request for a specific route.

This way it is possible to create a more flexible application without the need to write path specific code or to use a, less specific, middleware.

Let's take a look at an example:

::: code-group
```dart[auth_hook.dart]
class AuthHook extends Hook with OnBeforeHandle {
  @override
  Future<void> onBeforeHandle(RequestContext request) async {
    if (request.metadata.stat('NoAuth') != null) {
      return;
    }

    // Your code to check the Authorization here
  }
}
```

```dart[auth_controller.dart]
class AuthController extends Controller {

    AuthController(): super(path: '/auth') {
        on(
            Route.post(
                '/login', // This route will not be checked for Authorization
                metadata: [
                    Metadata(
                        name: 'NoAuth',
                        value: 'NoAuthValue',
                    ),
                ]
            ), 
            (RequestContext context) async {
                return 'Login';
            }
        );
        on(
            Route.get( // This route will be checked for Authorization
                '/logout',
            ),
            (RequestContext context) async {
                return 'Logout';
            }
        )
    }

}
```
:::
</BlogPage>