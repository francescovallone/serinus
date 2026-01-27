<script setup lang="ts">

import { ref } from 'vue';

const isOpen = ref(false);

</script>

<template>
	<div class="relative inline-block text-left w-full">
	<div>
	  <div
		@click="isOpen = !isOpen"
		type="button"
		class="flex h-10 items-center justify-between cursor-pointer border px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 [&>span]:line-clamp-1 w-full bg-background border-border"
		id="options-menu"
		aria-expanded="true"
		aria-haspopup="true"
	  >
		<slot name="trigger">Options</slot>
		<svg
		  :class="`ml-2 h-5 w-5 text-muted-foreground transition-transform ${isOpen ? 'rotate-180' : ''}`"
		  xmlns="http://www.w3.org/2000/svg"
		  viewBox="0 0 20 20"
		  fill="currentColor"
		  aria-hidden="true"
		>
		  <path
			fill-rule="evenodd"
			d="M5.23 7.21a.75.75 0 011.06.02L10 11.584l3.71-4.354a.75.75 0 111.14.976l-4.25 5a.75.75 0 01-1.14 0l-4.25-5a.75.75 0 01.02-1.06z"
			clip-rule="evenodd"
		  />
		</svg>
	  </div>
	</div>

	<div
	  v-if="isOpen"
	  class="origin-top-right absolute right-0 mt-2 w-full h-80 border border-border bg-background focus:outline-none z-30"
	  role="menu"
	  aria-orientation="vertical"
	  aria-labelledby="options-menu"
	>
	  <div class="py-1" role="none">
		<slot />
	  </div>
	</div>
  </div>
</template>