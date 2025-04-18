<script setup>
import { ref } from 'vue';

const copied = ref(false);
const downloads = ref(500);

function copyToClipboard(code) {
    navigator.clipboard.writeText(code);
    copied.value = true;
    setTimeout(() => copied.value = false, 1000);
}
</script>

<template>
	<div id="cli" class="flex flex-col w-full gap-8 py-16 justify-center items-center">
		<div class="flex flex-col gap-4 flex-1 items-center">
			<h1 class="text-3xl font-bold">
				Command your project with ease
			</h1>
			<p class="text-lg text-gray-400">
				Join over {{ downloads }} developers and start building your project with Serinus CLI.
			</p>
		</div>
		<div class="flex items-center mt-4 font-mono bg-neutral-800 p-4 rounded-lg">
            <span>$ dart pub global activate serinus_cli</span>
            <button class="ml-4 rounded-full font-semibold" @click="copyToClipboard('dart pub global activate serinus_cli')">
                <svg v-if="!copied" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></g></svg>
                <svg v-if="copied" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M21 10.5V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h12.5"/><path d="m9 11l3 3L22 4"/></g></svg>
            </button>
        </div>
	</div>
</template>

<style scoped>
p {
	margin: 0 !important;
}
.results{
	line-height: 1rem;
}
ol {
	padding: 0;
}
</style>