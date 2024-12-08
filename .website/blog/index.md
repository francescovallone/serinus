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
      title: 'Serinus VS Serverpod VS Dart Frog - A Comparison',
      src: '/blog/serinus_vs_serverpod_dartfrog/serinus_vs_serverpod_dartfrog.webp',
      alt: 'Serinus VS Serverpod VS Dart Frog - A Comparison',
      date: '29 Nov 2024',
      href: '/blog/serinux_vs_serverpod_dartfrog',
    },
    {
      title: 'Serinus 1.0 - Primavera',
      src: '/blog/serinus_1_0/serinus_1_0.webp',
      alt: 'Serinus 1.0 - Primavera',
      date: '26 Nov 2024',
      href: '/blog/serinus_1_0',
    },
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
