<script setup>
import { ref } from 'vue';

const plugins = [
	{
		title: 'OpenAPI',
		pub: 'https://pub.dev/packages/serinus_swagger',
		desc: 'Genearate Open API documentation for your Serinus project with no effort.',
		link: '/plugins/swagger/',
		slot: 'openapi'
	},
	{
		title: 'Configuration',
		pub: 'https://pub.dev/packages/serinus_config',
		desc: 'Manage your project configuration with a simple and easy to use package.',
		link: '/plugins/configuration',
		slot: 'configuration'
	},
	{
		title: 'Authentication',
		pub: 'https://pub.dev/packages/serinus_frontier',
		desc: 'Leverage the power of Serinus and Frontier to authenticate your users with ease.',
		link: '/plugins/frontier',
		slot: 'authentication'
	},
	{
		title: 'Cron Jobs',
		pub: 'https://pub.dev/packages/serinus_schedule',
		desc: 'Schedule tasks to run at specific intervals or times using cron syntax.',
		link: '/techniques/task_scheduling',
		slot: 'cron_jobs'
	}
]

const currentPlugin = ref(plugins[0]);

</script>

<template>
	<div class="flex w-full gap-8 flex-col py-16 px-64">
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
			<div class="text-base text-pretty text-gray-600 w-[52rem]">
				Designed to make backend development in Dart easy and enjoyable, Serinus offers a range of powerful features to help you build the best possible applications.
			</div>
		</div>
		<div class="container flex">
			<div class="selector flex flex-col gap-4 flex-1">
				<div v-for="plugin in plugins" :key="plugin.title" class="flex flex-col w-full">
					<div class="text-base text-pretty p-2 border-l-2 border-white" :class="{'border-color-serinus': currentPlugin.title === plugin.title, 'hover:border-gray-300': currentPlugin.title !== plugin.title}" @click="currentPlugin = plugin">
						{{ plugin.title }}
					</div>
				</div>
			</div>
			<div class="details flex flex-col gap-4 rounded-lg flex-1">
				<div class="text-base text-pretty text-gray-600">
					{{ currentPlugin.desc }}
				</div>
				<div>
					<slot :slot="currentPlugin.slot"></slot>
				</div>
				<div class="flex gap-4 items-center">
					<a :href="currentPlugin.link" class="bg-serinus hover:shadow-md transition-shadow px-6 py-3 rounded-md text-white font-semibold">Learn more</a>
					<a :href="currentPlugin.pub" target="_blank" class="px-6 py-3 hover:shadow-md transition-shadow font-semibold border border-gray-300 rounded-md">View on Pub.dev</a>
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