---
title: Serinus vs Serverpod vs Dartfrog
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Serinus vs Serverpod vs Dartfrog

    - - meta
      - name: 'description'
        content: How Serinus compares to Serverpod and Dartfrog? Let's find out.

    - - meta
      - property: 'og:description'
        content: How Serinus compares to Serverpod and Dartfrog? Let's find out.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/serinus_vs_serverpod_dartfrog/serinus_vs_serverpod_dartfrog.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/serinus_vs_serverpod_dartfrog/serinus_vs_serverpod_dartfrog.webp
---

<script setup>
    import BlogPage from '../components/blog_page.vue'
</script>

<BlogPage
    title="Serinus vs Serverpod vs Dartfrog"
    src="/blog/serinus_vs_serverpod_dartfrog/serinus_vs_serverpod_dartfrog.webp"
    alt="Serinus VS Serverpod VS Dart Frog - A Comparison"
    author="Francesco Vallone"
    date="29 Nov 2024"
    shadow
>

One of the questions I get asked the most is how Serinus compares to other similar projects. Why should you choose Serinus over Serverpod or Dartfrog? In this article, I will try to answer this question by comparing the three projects in terms of features and ease to use.

::: tip
You should pick what fits your needs the best.
:::

## Serverpod

Let's start with Serverpod.

Serverpod is "The missing server for Flutter" and while a lot of other projects are trying to do the same, Serverpod is actually the most complete and mature solution, with a lot of features and a big community. (I'm not affiliated with Serverpod in any way but it is the truth that they are doing a great job).

Serverpod comes in two versions: the full version and the mini version.

The full version is a complete solution that includes a lot of features like an ORM, cache, authentication, health checks and task scheduling, called `Future Calls` in Serverpod. The full version is a great solution if you need all these features and you don't want to use other libraries but it comes with a greater overhead and a slightly steeper learning curve since you need to learn how to use most of these features and also the Serverpod way of doing things.

The full version, also, uses PostgresSQL as the default database and Redis to store the cache. The latter is not enabled by default but you can enable it by changing a configuration file.

The mini version is a stripped-down version of the full version. It also allows you to use other databases like SQLite and MySQL but it doesn't include all the features of the full version. It is a great solution if you don't need all the features of the full version and you want to use other libraries for some of them.

In the end, Serverpod is great if you want to use a complete solution that includes a lot of features and you don't want to use other libraries. They are also ahead in terms of features and maturity having been around for a longer time and having a bigger community.

::: tip
I love the Streaming API of Serverpod. It just works as intended and it is very easy to use.
:::

If you want to learn more about Serverpod, you can visit their [website](https://serverpod.dev).

## Dartfrog



</BlogPage>
