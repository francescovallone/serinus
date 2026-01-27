<script setup>
import { useRoute } from 'vitepress';
import { computed } from 'vue';
import { ArrowUpRightIcon, XSocialIcon, LinkedInSocialIcon, LinkIcon } from './home/icons';

const route = useRoute();

const url = `https://serinus.app${route.path}`;

const computedPath = computed(() => {
  return encodeURI(`Check out this article\n${route.data.frontmatter.title}\n\n${url}. 🐤💙`)
});

const links = [
	{
	  name: 'X',
	  href: `https://x.com/intent/post?text=${computedPath.value}`,
	  icon: XSocialIcon
  },
  {
    name: "LinkedIn",
    icon: LinkedInSocialIcon,
    href: `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url)}`,
  },
  {
    name: 'Copy Link',
    icon: LinkIcon,
    href: url,
  }
]

</script>

<template>
	<div class="flex items-center gap-2">
      <span class="text-xs font-mono text-muted-foreground uppercase tracking-wider mr-2">
        Share
      </span>
      <a
        :key="link.name"
        :href="link.href"
        target="_blank"
        rel="noopener noreferrer"
        class="p-2 border border-border hover:border-primary! hover:text-primary! transition-colors"
        :aria-label='`Share on ${link.name}`'
        v-for="link in links"
    >
      <component :is="link.icon" class="w-4 h-4" />
    </a>
    </div>
</template>

<style scoped>
.vp-doc a {
  color: unset !important;
}
</style>