<script setup>
import Fast from './fast.vue'
import Modular from './modular.vue'
import Hero from './hero.vue'
</script>

<template>
	<div class="flex flex-col gap-16">
		<Hero class="h-screen" />
		<Fast />
		<div class="flex md:flex-row w-full gap-8">
			<div class="flex flex-col w-full">
				<section class="flex flex-col gap-6 flex-1">
					<h1 class="text-2xl font-bold">Join the community! ✨</h1>
					<p class="text-xl text-gray-400">
						Serinus is a community-first framework! It means that we value the community and we want to build a friendly and welcoming environment for everyone. Join our Discord server to chat with other developers, ask questions, and get help with your projects.
					</p>
				</section>
			</div>
			<div class="flex flex-col w-full">
				<iframe 
					src="https://discord.com/widget?id=1099781506978807919&theme=dark" 
					class="w-full h-64" 
					allowtransparency="true" 
					frameborder="0" 
					sandbox="allow-popups allow-popups-to-escape-sandbox allow-same-origin allow-scripts"
				/>
			</div>
		</div>
		<Modular />
	</div>
</template>