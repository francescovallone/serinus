---
title: Serinus Blog
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
</script>

<Blog
	:posts="[
    {
      title: 'The goal of Serinus',
      src: '/blog/the_goal_of_serinus/the_goal_of_serinus.webp',
      alt: 'The goal of Serinus',
      date: '04 Nov 2024',
      href: '/blog/the_goal_of_serinus',
    },
		{
			title: 'Serinus 0.6 - Welcome to the Meta-World',
			src: '/blog/serinus_0_6/serinus_0_6.webp',
			alt: 'Serinus 0.6 - Welcome to the Meta-World',
			date: '1 Aug 2024',
			href: '/blog/serinus_0_6',
		},
	]"
/>
