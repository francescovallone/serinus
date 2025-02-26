---
title: Serinus vs Dart Frog - A Comparison
description: A comparison between Serinus and Dart Frog, two server-side frameworks for Flutter.
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Serinus vs Dart Frog - A Comparison

    - - meta
      - name: 'description'
        content: A comparison between Serinus and Dart Frog, two server-side frameworks for Flutter.

    - - meta
      - property: 'og:description'
        content: A comparison between Serinus and Dart Frog, two server-side frameworks for Flutter.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp
---

<script setup>
    import BlogPage from '../components/blog_page.vue'
</script>

<BlogPage
    title="Serinus vs Dartfrog"
    src="/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp"
    alt="Serinus VS Dart Frog - A Comparison"
    author="Francesco Vallone"
    date="26 Feb 2025"
    shadow
>

One of the questions I get asked the most is how Serinus compares to other similar projects. Why should you choose Serinus over Dartfrog? In this article, I will try to answer this question by comparing the three projects in terms of features and ease to use.

::: tip
You should pick what fits your needs the best.
:::

## Dart Frog

Dart Frog is a server-side framework for Flutter that allows you to build server-side applications using the Dart programming language. It is a wrapper around Shelf and tries to provide a more simple and easy to use API.

### Features

- **File-system routing**: Dart Frog uses the file system to define routes. This is a very simple and intuitive way to define routes.
- **Dependency Injection**: Dart Frog has a built-in dependency injection system that allows you to inject dependencies into your handlers.
- **Static Files support**: Dart Frog has built-in support for serving static files.
- **Websockets**: Dart Frog has support for Websockets by using a first-party plugin.
- **Hot Reload**: Dart Frog has support for hot reload out of the box.
- **VS Code Extension**: Dart Frog has a VS Code extension that allows you to create new projects and run them directly from the editor.

### Opinions

While it is true that Dart Frog is a very simple and easy to use framework, it has some issues that I want to address.

For starters, the file-system routing is a very simple way to define routes, but it can become a mess very quickly if you have a lot of routes. It is also not very flexible and does not allow you to define complex routes. Although the Dart Frog team added a support for wildcards.

The dependency injection system leverages the middleware system of Shelf, which is a very powerful feature. However, it can easily become messy if you want to inject a lot of dependencies into your handlers.

## Serinus

Well, I am the author of Serinus, so I am a bit biased. But I will try to be as objective as possible.

Serinus is a server-side framework for Flutter that allows you to build server-side applications using the Dart programming language. It tries to provide a more flexible and extensible API giving you more control over your application.

### Features

- **Hooks**: Serinus has a powerful hooks system that allows you to run your code throughout the request lifecycle.
- **Dependency Injection**: Serinus has a built-in dependency injection system that allows you to inject dependencies into your modules.
- **Metadata**: Serinus provides a metadata system to specialize your routes and controllers with custom data.
- **Typed Body Handlers**: Serinus has a built-in system to parse the request body into a Dart object.
- **Tracer**: Serinus provides a built-in system to trace different request lifecycle events and custom events.
- **Validation Schema**: Leverage the power of the `acanthis` or any other validation package to validate your request body.

### Opinions

Serinus is a more complex framework compared to Dart Frog, but it gives you more control over your application. The hooks system is very powerful and allows you to run your code throughout the request lifecycle allowing you to, for example, block a request before it reaches the handler.

The dependency injection system is also very flexible and allows you to inject dependencies into your modules and providers easily. 

Lastly, the metadata system is a very powerful feature that allows you to specialize your routes and controllers with custom data that can be accessed in hooks or in the handlers.

## Conclusion

Both Serinus and Dart Frog are great frameworks that allow you to build server-side applications using the Dart programming language. They have different philosophies and features, so you should pick the one that fits your needs the best.

But if you want more control over your application and you want to leverage the power of hooks, metadata, a more flexible dependency injection system, and a more structured approach then Serinus is the right choice for you.

</BlogPage>
