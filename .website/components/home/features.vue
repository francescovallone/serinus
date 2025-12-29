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
			<h1 class="font-semibold text-3xl text-white">Everything you need</h1>
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