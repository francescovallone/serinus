<script setup>
import { computed, defineProps, ref } from 'vue'

const props = defineProps({
    posts: Array
})

const currentTopic = ref('')

function changeTopic(topic) {
	currentTopic.value = topic
}

const filteredPosts = computed(() => {
	if (currentTopic.value === '') {
		return props.posts
	}
	return props.posts.filter((post) => post.tags.includes(currentTopic.value))
})

const topics = computed(() => {
	const tags = []
	props.posts.forEach((post) => {
		post.tags.forEach((tag) => {
			if (!tags.includes(tag)) {
				tags.push(tag)
			}
		})
	})
	return tags
})

</script>

<template>

	<div>
		<header class="flex flex-col justify-center container gap-2 w-full mx-auto pt-20 p-4">
			<h1 class="text-3xl font-semibold text-white">
				Blog
			</h1>
			<p class="text-white text-md">
				Updates, tutorials, and more from the Serinus team.
			</p>
			<div class="flex gap-4">
				<button @click="changeTopic('')" class="tag text-xs font-medium tracking-wide uppercase max-w-fit p-2 rounded-full" :class="currentTopic === '' ? '' : 'inactive'">All</button>
				<button 
					v-for="topic in topics" 
					@click="changeTopic(topic)" 
					:key="topic" 
					class="tag text-xs font-medium tracking-wide uppercase max-w-fit p-2 rounded-full"
					:class="currentTopic === topic ? '' : 'inactive'"
				>
					{{ topic }}
				</button>
			</div>
		</header>
		<main class="grid grid-cols-6 gap-8 container mx-auto my-8">
			<a v-for="post in filteredPosts"
				class="p-4 rounded-lg hover:bg-orange-500/25 focus:bg-orange-500/25 transition-colors cursor-pointer flex flex-col gap-2 md:col-span-3 col-span-6"
				:href="post.href" :key="post.date + post.href">
				<article class="flex flex-col gap-4">
					<img :src="post.src" :alt="post.alt" class="rounded-lg" />
					<h2 class="text-2xl font-bold">
						{{ post.title }}
					</h2>
					<div class="flex justify-between">
						<p v-for="tag in post.tags" :key="tag" class="tag text-xs font-medium tracking-wide uppercase max-w-fit p-2 rounded-full">
							{{ tag }}
						</p>
						<h3 class="text-sm text-gray-400"> {{ post.date }}</h3>
					</div>
					
				</article>
			</a>
		</main>
	</div>
    
</template>

<style scoped>
.tag {
	background-color: var(--vp-c-brand-darker);
}
.tag.inactive {
	background-color: transparent;
}
</style>