<script setup>
import { computed, ref } from 'vue'

const props = defineProps({
    posts: Array,
	title: String,
	desc: String,
	blog: Boolean
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

	<div class="2xl:px-64 lg:px-16 px-8 w-full flex flex-col">
		<header class="flex flex-col justify-center container gap-4 w-full mx-auto pt-20 p-4">
			<h1 class="text-6xl font-semibold">
				{{title ?? 'Blog'}}
			</h1>
			<p class="text-md">
				{{desc ?? 'Read the latest articles on Serinus and related topics.'}}
			</p>
			<div v-if="blog" class="flex gap-4 my-2">
				<div @click="changeTopic('')" class="px-4 py-2 hover:shadow-md transition-shadow font-semibold rounded-md capitalize cursor-pointer" :class="currentTopic === '' ? 'bg-serinus text-white' : 'border border-gray-300'">All</div>
				<div 
					v-for="topic in topics" 
					@click="changeTopic(topic)" 
					:key="topic" 
					class="px-4 py-2 hover:shadow-md transition-shadow font-semibold rounded-md capitalize cursor-pointer"
					:class="currentTopic === topic ? 'bg-serinus text-white' : 'border border-gray-300'"
				>
					{{ topic }}
				</div>
			</div>
		</header>
		<main class="grid grid-cols-6 gap-8 mx-auto my-8">
			<a v-for="post in filteredPosts"
				class="p-4 rounded-lg hover:shadow-md transition-shadow cursor-pointer flex flex-col gap-2 md:col-span-2 col-span-6 border-dashed border-2 border-gray-300"
				:href="post.href" :key="post.date + post.href">
				<article class="flex flex-col gap-4 h-full justify-between">
					<div class="flex flex-col gap-2">
						<img :src="post.src" :alt="post.alt" class="rounded-lg" />
						<h2 class="text-2xl font-bold">
							{{ post.title }}
						</h2>
					</div>
					<div class="flex justify-between items-end">
						<p v-for="tag in post.tags" :key="tag" class="text-xs font-medium tracking-wide uppercase text-serinus">
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