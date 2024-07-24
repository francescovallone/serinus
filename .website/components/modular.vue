<script setup>
const plugins = [
	{
		title: 'Swagger',
		pub: 'https://pub.dev/packages/serinus_swagger',
		desc: 'Automatically generate OpenAPI documentation for your API.',
		gh: 'https://github.com/serinus-nest/serinus_swagger',
		link: '/plugins/swagger/',
	},
	{
		title: 'Config',
		pub: 'https://pub.dev/packages/serinus_config',
		desc: 'Access .env files and environment variables with ease.',
		gh: 'https://github.com/serinus-nest/serinus_config',
		link: '/plugins/configuration',
	},
]

</script>

<template>
	<div class="container flex w-full gap-8 flex-col my-8">
		<div class="container flex w-full gap-8 flex-col lg:flex-row">
			<section class="flex flex-col gap-6 flex-1">
				<h1 class="text-2xl font-bold">Modular 📦</h1>
				<p class="text-xl text-gray-400">
					Serinus is designed to be modular and extensible. It allows you to create your own modules and plugins to extend its functionality.
				</p>
				<p class="text-xl text-gray-400">
					Here are some of the plugins that are available for Serinus
				</p>
			</section>
			<section class="flex flex-col gap-4 flex-1">
				<a v-for="plugin in plugins" :key="plugin.title" class="plugin transition-all bg-neutral-900 p-4 rounded-lg" :href="plugin.link">
					<div class="flex justify-between items-center">
						<p class="text-lg">{{ plugin.title }}</p>
						<div class="flex gap-2">
							<a class="text-gray-400 text-sm" :href="plugin.pub">Pub</a>
							<a class="text-gray-400 text-sm" :href="plugin.gh">GitHub</a>
						</div>
					</div>
					<p class="text-gray-400">{{ plugin.desc }}</p>
				</a>
			</section>
		</div>
		<div class="flex justify-center" style="flex-shrink: 0; padding: 6px">
			<a href="/plugins/" class="border-orange-400 border-2 rounded-full px-8 py-4">
				View all plugins
			</a>
		</div>
  	</div>
</template>

<style scoped>
p {
	margin: 0;
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