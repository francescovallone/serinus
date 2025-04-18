---
title: Serinus 0.6 - Welcome to the Meta-World
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Serinus 0.6 - Welcome to the Meta-World

    - - meta
      - name: 'description'
        content: Introducing Metadata, Tracers, Generate Command, StreamableResponses, breaking changes, bug fixes, revamps, documentation, and other changes in Serinus 0.6.

    - - meta
      - property: 'og:description'
        content: Introducing Metadata, Tracers, Generate Command, StreamableResponses, breaking changes, bug fixes, revamps, documentation, and other changes in Serinus 0.6.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/serinus_0_6/serinus_0_6.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/serinus_0_6/serinus_0_6.webp
---
<script setup>
	import BlogPage from '../components/blog_page.vue'
</script>

<BlogPage
	title="Serinus 0.6 - Welcome to the Meta-World"
	src="/blog/serinus_0_6/serinus_0_6.webp"
	alt="Serinus 0.6 - Welcome to the Meta-World"
	author="Francesco Vallone"
	date="1 Aug 2024"
  :tags="['releases']"
	shadow
>
Serinus 0.6, brings a lot of changes to the code base to improve the developer experience and to stabilize even more the framework. With 5,440 additions and 1,651 deletions. Serinus 0.6 is one of the biggest updates ever occured to the project.

But let’s dive into the new features, the breaking changes, the fixes and the revamps made to the framework.

## Features

### Metadata

A new Metadata system has been implemented in Serinus. It can be used to specialize even more the routes or the controllers and can provide both contextualized values and raw values. You can read more of it [here](/metadata.html).

### Tracers

One of the features that should’ve been present in the 0.5 but didn’t make it, but here it is. You can now trace the time elapsed between each step of the request lifecycle effortlessly. You can also use more tracer at the same time in your application with minimum impact on the performances. You can read more of it [here](/tracer).

### Generate Command

A new command has been added to the CLI that allows new resources to be generated for the project. The available options are modules, providers, controllers and resources, which will create them all in one go. You can read more of it [here](/cli/generate.html).

### StreamableResponses

A new way to create a response has been implemented. From the RequestContext is now possible to start a StreamedResponses sending the data in chunks instead that in one go.

## Breaking Changes

> With great changes comes some breaking ones.

### Request Handling

The chains of the Response object have been broken! You can now return whatever object you want and Serinus will try to serialize it and handle it. Also since the Response object has been removed from Serinus to change the properties of the response you can now access a _ResponseProperties_ object in the _RequestContext_ using _context.res_.

### ParseSchema

One of the core rules of Serinus is that the developer should use whatever tool he wants, and while the team is still working in making Serinus more open, this is a step in the right direction. Out of the box Serinus will provide the AcanthisParseSchema that will use the Acanthis library (another bird of Serinus Nest) but you can also create your own parse schema simply extending the ParseSchema class. You can read more of it [here](/techniques/validation.html).

## Bug fixes

> Not proud of these.

### Providers dependencies

The providers of the parent weren’t available in the RequestContexts of the children routes making really hard to manage the dependencies. This bug has now been fixed and all the parent providers are available in its children.

### Shelf Interoperability

The Shelf Interoperability unfortunately had some problem when managing more middlewares that could return a response. You can now decide of which middleware you want to accept the response setting the new parameter _ignoreResponse_ to false. You can read more of it [here](/middlewares).

## Revamps

### Documentation

The whole documentation have been updated and improved to explain the mechanism behind Serinus in a easier way. The design of the homepage has also been modified and in general the documentation has been divided in more sections to make sure that you focus on the correct content.

### Serinus

What but how? Well since Serinus aims to be as open as possible to changes since this version more internal stuff are now available for you to use to create whatever you need.

## Other changes

The Serinus repository now host all the packages and plugins available for Serinus itself.

## Conclusion

Serinus 0.6 offers new features and improve the developer experience without affecting the performances.
</BlogPage>
