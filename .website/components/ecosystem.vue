<script setup>
const plugins = [
	{
		title: 'Swagger',
		pub: 'https://pub.dev/packages/serinus_swagger',
		desc: 'Genearate Open API documentation for your Serinus project with no effort.',
		link: '/plugins/swagger/',
	},
	{
		title: 'Config',
		pub: 'https://pub.dev/packages/serinus_config',
		desc: 'Manage your project configuration with a simple and easy to use package.',
		link: '/plugins/configuration',
	},
	{
		title: 'Frontier',
		pub: 'https://pub.dev/packages/serinus_frontier',
		desc: 'Leverage the power of Serinus and Frontier to authenticate your users with ease.',
		link: '/plugins/frontier',
	},
]

</script>

<template>
	<div class="flex w-full gap-8 flex-col my-12 justify-center items-center">
		<div class="container flex gap-8 flex-col items-center">
			<section class="flex flex-col gap-4 flex-1 items-center">
				<h1 class="text-3xl font-bold">
					Don't reinvent the wheel
				</h1>
				<p class="text-lg text-gray-400">
					Extend Serinus with plugins to add more functionality to your project with ease.
				</p>
			</section>
			<section class="container grid grid-cols-6 gap-8">
				<div 
					v-for="(plugin, index) in plugins" 
					:key="plugin.title" 
					class="plugin transition-all bg-neutral-900 p-8 rounded-xl flex flex-col gap-4"
					:class="plugins.length % 2 !== 0 && index === plugins.length - 1 ? 'col-span-6' : 'col-span-3'"
				>
					<h1 class="text-2xl font-semibold">
						{{ plugin.title }}
					</h1>
					<p class="text-md">{{ plugin.desc }}</p>
					<div class="flex gap-4">
						<a :href="plugin.pub" class="bg-orange-400 text-white px-4 py-2 rounded-lg">
							Pub.dev
						</a>
						<a :href="plugin.link" class="bg-orange-400 text-white px-4 py-2 rounded-lg">
							Documentation
						</a>
					</div>
				</div>
			</section>
		</div>
		<div class="flex justify-center" style="flex-shrink: 0; padding: 6px">
			<a href="/plugins/" class="bg-orange-400 px-8 py-4 rounded-full text-white font-semibold">
				View all plugins
			</a>
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
.plugin {
	border: 1px solid transparent;
}
.plugin:hover {
	border: 1px solid var(--vp-c-brand-2);
}
</style>