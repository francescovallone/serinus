---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

---

<script setup>
  import Home from './components/home.vue';
  // import Modular from './components/modular.vue';
</script>

<Home />

hero:
  name: "Serinus"
  image:
    src: /serinus-logo.png
    alt: Serinus
  tagline: A backend framework written in Dart 🎯 for building efficient and scalable server-side applications.
  actions:
    - theme: brand
      text: Get Started
      link: /introduction
    - theme: alt
      text: Source code
      link: http://github.com/francescovallone/serinus