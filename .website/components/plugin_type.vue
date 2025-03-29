<script setup>

	const props = defineProps({
		types: Array,
	})

</script>

<template>
	<div class="flex gap-2 flex-wrap">
		<p v-for="type in props.types" :key="type" style="margin-bottom: 0; line-height: 1rem;" class="tag flex gap-2 mb-0 text-xs font-medium tracking-wide uppercase max-w-fit p-2 text-neutral-900 rounded-lg">
			{{ type }}
		</p>
	</div>
</template>

<style scoped>
.tag {
	background-color: var(--vp-c-brand-1);
}
.tag.inactive {
	background-color: transparent;
}
</style>