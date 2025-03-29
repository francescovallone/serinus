<script setup>

const props = defineProps({
	buttons: {
		label: String,
		url: String,
	},
})

</script>

<template>
	<div class="flex md:flex-row flex-col gap-2 flex-wrap">
		<a v-for="button in props.buttons" :key="button.label" :href="button.url" style="margin-bottom: 0; line-height: 1rem; background-color: rgb(23,23,23);" class="flex grow gap-2 mb-0 text-sm font-medium tracking-wide uppercase p-4 text-white rounded-lg items-center justify-between">
			<span>{{ button.label }}</span>
			<span>
				<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h10v10M7 17L17 7"/></svg>
			</span>
		</a>
	</div>
</template>

<style scoped>
a {
	text-decoration: none;
	color: var(--vp-c-brand-1);
}
</style>