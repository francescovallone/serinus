<script setup>
// import { ref } from 'vue'
// import GraphLine from './graph_line.vue'
// const graphs = [
// 	{
// 		title: 'Serinus',
// 		lang: 'Dart',
// 		value: 6831,
// 		latency: 4.1,
// 		memory: 15.7
// 	},
// 	{
// 		title: 'Express',
// 		lang: 'Node',
// 		value: 6799,
// 		latency: 4.5,
// 		memory: 63.1
// 	},
// 	{
// 		title: 'Nest',
// 		lang: 'Node',
// 		value: 	6352,
// 		latency: 4.8,
// 		memory: 82.6
// 	},
// 	{
// 		title: 'Shelf',
// 		lang: 'Dart',
// 		value: 6311,
// 		latency: 4.4,
// 		memory: 16.4
// 	},
// 	{
// 		title: 'Dart Frog',
// 		lang: 'Dart',
// 		value: 5875,
// 		latency: 4.8,
// 		memory: 15.8
// 	},
// 	{
// 		title: 'Django',
// 		lang: 'Python',
// 		value: 949,
// 		latency: 23.7,
// 		memory: 85.7
// 	}
// ]
// const tab = ref(0)
// let max = Math.max(...graphs.map((graph) => graph.value))
// let label = 'req/s'
// function changeTab(index) {
// 	tab.value = index
// 	switch(index) {
// 		case 0:
// 			max = Math.max(...graphs.map((graph) => graph.value))
// 			label = 'req/s'
// 			graphs.sort((a, b) => b.value - a.value)
// 			break
// 		case 1:
// 			max = Math.max(...graphs.map((graph) => graph.latency))
// 			label = 'ms'
// 			graphs.sort((a, b) => a.latency - b.latency)
// 			break
// 		case 2:
// 			max = Math.max(...graphs.map((graph) => graph.memory))
// 			label = 'MB'
// 			graphs.sort((a, b) => a.memory - b.memory)
// 			break
// 	}
// }
</script>

<template>
	<div id="features" class="flex w-full gap-8 lg:flex-row flex-col py-16 justify-center items-center">
		<div class="container flex lg:flex-row justify-center items-center gap-8">
			<div class="p-4 flex justify-center items-center">
				<div class="flex flex-col items-center">
					<img src="/distribute-icon.svg" alt="Serinus Logo" class="w-20 h-20" />
					<div class="mt-8 mb-4 text-xl text-pretty tracking-wide uppercase text-center font-semibold text-[#FF9800]">
						Modular
					</div>
					<div class="text-md text-pretty text-center w-80">
						Flexible and modular architecture that allows you to build your application the way you want.
					</div>
				</div>
			</div>
			<div class="p-4 flex justify-center items-center">
				<div class="flex flex-col items-center">
					<img src="/product-launch-release-icon.svg" alt="Serinus Logo" class="w-20 h-20" />
					<div class="mt-8 mb-4 text-xl text-pretty tracking-wide uppercase text-center font-semibold text-[#FF9800]">
						Performant
					</div>
					<div class="text-md text-pretty text-center w-80">
						Optimized for performance and scalability, Serinus can handle thousands of requests per second.
					</div>
				</div>
			</div>
			<div class="p-4 rounded-2xl flex justify-center items-center">
				<div class="flex flex-col items-center">
					<img src="/target-icon.svg" alt="Serinus Logo" class="w-20 h-20" />
					<div class="mt-8 mb-4 text-xl text-pretty tracking-wide uppercase text-center font-semibold text-[#FF9800]">
						Predictable
					</div>
					<div class="text-md text-pretty text-center w-80">
						With a strong type system and a powerful dependency injection system, Serinus is predictable and reliable.
					</div>
				</div>
			</div>
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