<script setup>
defineProps({
	title: String,
	description: String,
	link: String
})
</script>

<template>
	<a :href="link" class="p-4 flex flex-col gap-2 bg-gray-950/25 rounded-lg !no-underline border-2 border-transparent !transition-all !ease-in-out hover:border-orange-500">
		<h3 class="text-md text-white !m-0">{{ title }}</h3>
		<p class="text-sm text-gray-400 !m-0">{{ description }}</p>
	</a>
</template>