---
title: Why Dart Backends Need Architecture, Not Just Scaffolding
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Why Dart Backends Need Architecture, Not Just Scaffolding

    - - meta
      - name: 'description'
        content: Dart has proven to be a great language for building frontend applications, but on the server, it's often treated as a shortcut language. This article discusses why backend applications need architecture, not just scaffolding.

    - - meta
      - property: 'og:description'
        content: Dart has proven to be a great language for building frontend applications, but on the server, it's often treated as a shortcut language. This article discusses why backend applications need architecture, not just scaffolding.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/architecture_over_scaffolding/architecture_over_scaffolding.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/architecture_over_scaffolding/architecture_over_scaffolding.webp
---
<script setup>
	import BlogPage from '../components/blog/blog_page.vue'
</script>

<BlogPage
	title="Why Dart Backends Need Architecture, Not Just Scaffolding"
	src="/blog/architecture_over_scaffolding/architecture_over_scaffolding.webp"
	alt="Why Dart Backends Need Architecture, Not Just Scaffolding"
	author="Francesco Vallone"
	date="01 Jan 2025"
	:tags="['general']"
	shadow
>

Over the last years, Dart has proven over and over again to be a great language for building frontend applications, Flutter being the prime example of this. On the server, however, Dart is still treated like a shortcut language, something you use to avoid context switching, not something you design systems with.

That's a mistake. Because backends don't fail due to syntax choices. They succomb to architectural debt. And to be honest, architecture can't be scaffolded into existence.

## The problem isn't Dart, it's mindset

When people talk about Dart backends, the conversation almost always starts with speed:

- "How fast can I get an API running?""
- “How much boilerplate does this remove?”
- “How little backend knowledge do I need?”

These are understandable questions because DX is important to ensure a smooth experience when working with a new technology, but they are also the wrong ones.
A backend system is not a demo artifact.
It’s a system that evolves, accumulates responsibility, and eventually becomes critical infrastructure.

Optimizing only for speed at the beginning guarantees pain later.

## Scaffolding solves the wrong problems

Scaffolding tools are greate for one thing:

> Making the first commit feel good.

They generate code, set up folders, and create a basic structure for your application, everything from the get-go.



</BlogPage>