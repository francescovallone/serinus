<script setup>
const props = defineProps({
    posts: Array
})

</script>

<template>

	<div>
		<header class="flex flex-col justify-center items-center max-w-3xl gap-3 w-full mx-auto pt-20 pb-4">
			<h1 class="text-5xl font-bold">
				Serinus Blog
			</h1>
			<p class="text-gray-300 text-lg">
				Release notes, updates, and more.
			</p>
		</header>
		<main class="flex flex-col max-w-xl gap-4 w-full mx-auto my-8">
			<a v-for="(post, index) in props.posts"
				class="p-4 rounded-lg hover:bg-orange-500/25 focus:bg-orange-500/25 transition-colors cursor-pointer"
				:href="post.href" :key="post.date + post.href">
				<article v-if="index == 0" class="flex flex-col gap-2">
					<img :src="post.src" :alt="post.alt" class="rounded-lg" />
					<h2 class="text-3xl font-bold">
						{{ post.title }}
					</h2>
					<h3 class="text-sm text-gray-400"> {{ post.date }}</h3>
				</article>
				<article v-if="index > 0" class="flex gap-2">
					<div class="rounded-lg w-24 h-24 bg-cover bg-center" :style="'background-image: url('+post.src+')'"></div>
					<div class="flex flex-col gap-2">
						<h2 class="text-2xl font-bold">
							{{ post.title }}
						</h2>
						<h3 class="text-sm text-gray-400"> {{ post.date }}</h3>
					</div>
				</article>
			</a>
		</main>
	</div>
    
</template>