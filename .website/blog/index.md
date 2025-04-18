---
title: Blog
layout: page
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Blog - Serinus

    - - meta
      - name: 'description'
        content: Updates and release notes of Serinus

    - - meta
      - property: 'og:description'
        content: Updates and release notes of Serinus
---

<script setup>
    import Blog from '../components/blog.vue'
    import { posts } from '../components/data/blog.ts'
</script>

<Blog :posts="posts"/>
