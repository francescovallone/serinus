<script setup>
import { useRoute } from 'vitepress';
import { computed } from 'vue';

const route = useRoute();

const computedPath = computed(() => {
  return encodeURI(`Check out this article\n${route.data.frontmatter.title}\n\nhttps://serinus.app${route.path}. 🐤💙`)
});

</script>

<template>
  	<div class="flex flex-col gap-4 border-t pt-2 mt-8">
		<h3>Enjoyed the article?</h3>
		<div class="flex flex-wrap gap-4">
			<a :href="'https://x.com/intent/post?text=' + computedPath" target="_blank" class="flex p-2 hover:shadow-md transition-shadow no-underline font-semibold items-center justify-center gap-1 border text-base text-center lg:text-start w-auto border-gray-300 rounded-md">
				<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><path fill="currentColor" d="m17.687 3.063l-4.996 5.711l-4.32-5.711H2.112l7.477 9.776l-7.086 8.099h3.034l5.469-6.25l4.78 6.25h6.102l-7.794-10.304l6.625-7.571zm-1.064 16.06L5.654 4.782h1.803l10.846 14.34z"/></svg>
				Share it
			</a>
		</div>
	</div>
</template>

<style scoped>
a {
	text-decoration: none !important;
}
</style>