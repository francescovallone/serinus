<script setup>
import { ref } from 'vue';
import { plugins } from './data/ecosystem.ts';

const currentPlugin = ref(plugins[0]);

const changePlugin = (event, selectedPlugin) => {
	event.currentTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
	if (selectedPlugin) {
		currentPlugin.value = selectedPlugin;
	}
};

</script>

<template>
	<div class="flex w-full gap-8 flex-col md:py-16 py-4 2xl:px-64 md:px-16 px-8">
		<div class="flex gap-8 items-center">
			<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="#FF9800" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m7 8l-4 4l4 4m10-8l4 4l-4 4M14 4l-4 16"/></svg>
			<div class="text-lg text-pretty text-serinus tracking-wide">
				Ecosystem
			</div>
		</div>
		<div class="flex flex-col gap-2">
			<div class="text-3xl text-pretty">
				A robust ecosystem for every need
			</div>
			<div class="text-base text-pretty text-gray-600 2xl:w-[52rem] lg:w-[36rem] w-full">
				Designed to make backend development in Dart easy and enjoyable, Serinus offers a range of powerful features to help you build the best possible applications.
			</div>
		</div>
		<div class="flex flex-col md:flex-row gap-8">
			<div class="selector flex md:flex-col gap-4 overflow-auto flex-1 md:max-w-[300px] tabs">
				<div v-for="plugin in plugins" :key="plugin.title" class="flex flex-col w-full min-w-[120px] text-center md:text-start">
					<div class="text-base text-pretty p-2 md:border-l-2 md:border-b-0 border-b-2 border-bg cursor-pointer" :class="{'border-color-serinus': currentPlugin.title === plugin.title, 'hover:border-gray-300': currentPlugin.title !== plugin.title}" @click="(event) => changePlugin(event, plugin)">
						{{ plugin.title }}
					</div>
				</div>
			</div>
			<div class="details flex flex-col gap-4 rounded-lg flex-1">
				<div class="display">
					<slot :name="currentPlugin.slot" :slot="currentPlugin.slot"></slot>
				</div>
				<div class="flex gap-4 items-center">
					<a :href="currentPlugin.link" class="text-serinus hover:shadow-md transition-shadow py-3 text-sm underline">Read {{ currentPlugin.title }} docs</a>
				</div>
			</div>
		</div>
  	</div>
</template>

<style scoped>
.vp-doc p, .vp-doc summary {
	margin: 0 !important;
}
.results{
	line-height: 1rem;
}
ol {
	padding: 0;
}
.vp-doc a{
	text-decoration: none;
}
.vp-doc a.bg-orange-400 {
	color: white;
}
</style>
<style>
.tabs::-webkit-scrollbar {
  display: none;
}
.tabs {
	scrollbar-width: none;
	-ms-overflow-style: none;
}
.display h3 {
	@apply text-lg font-semibold text-pretty;
}
.display p {
	@apply text-base text-gray-500 my-4;
}
.display p .numbered {
	@apply font-bold pr-4;
}
</style>