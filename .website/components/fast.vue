<script setup>
import { ref } from 'vue'
import GraphLine from './graph_line.vue'
const graphs = [
	{
		title: 'Serinus',
		lang: 'Dart',
		value: 6831,
		latency: 4.1,
		memory: 15.7
	},
	{
		title: 'Express',
		lang: 'Node',
		value: 6799,
		latency: 4.5,
		memory: 63.1
	},
	{
		title: 'Nest',
		lang: 'Node',
		value: 	6352,
		latency: 4.8,
		memory: 82.6
	},
	{
		title: 'Shelf',
		lang: 'Dart',
		value: 6311,
		latency: 4.4,
		memory: 16.4
	},
	{
		title: 'Dart Frog',
		lang: 'Dart',
		value: 5875,
		latency: 4.8,
		memory: 15.8
	},
	{
		title: 'Django',
		lang: 'Python',
		value: 949,
		latency: 23.7,
		memory: 85.7
	}
]
const tab = ref(0)
let max = Math.max(...graphs.map((graph) => graph.value))
let label = 'req/s'
function changeTab(index) {
	tab.value = index
	switch(index) {
		case 0:
			max = Math.max(...graphs.map((graph) => graph.value))
			label = 'req/s'
			graphs.sort((a, b) => b.value - a.value)
			break
		case 1:
			max = Math.max(...graphs.map((graph) => graph.latency))
			label = 'ms'
			graphs.sort((a, b) => a.latency - b.latency)
			break
		case 2:
			max = Math.max(...graphs.map((graph) => graph.memory))
			label = 'MB'
			graphs.sort((a, b) => a.memory - b.memory)
			break
	}
}
</script>

<template>
	<div id="performant" class="container flex w-full gap-8 lg:flex-row flex-col my-8">
		<section class="flex flex-col gap-6 flex-1">
			<h1 class="text-2xl font-bold">Performant 🚀</h1>
			<p class="text-xl text-gray-400">
				Serinus is designed to be performant and efficient. It is built on top of the Dart language, which is known for its performance and efficiency.
			</p>
			<p class="text-xl text-gray-400">
				Here are some benchmarks comparing Serinus with other popular frameworks.
			</p>
		</section>
		<section class="flex flex-col gap-4 flex-1">
			<div class="flex gap-4 justify-evenly">
				<button
					@click="changeTab(0)"
					:class="tab === 0 ? 'text-orange-500' : ''"
					class="tab px-4 py-2 hover:text-orange-400 transition-colors"
				>
					RPS
				</button>
				<button
					@click="changeTab(1)"
					:class="tab === 1 ? 'text-orange-500' : ''"
					class="tab px-4 py-2 hover:text-orange-400 transition-colors"
				>
					Latency
				</button>
				<button
					@click="changeTab(2)"
					:class="tab === 2 ? 'text-orange-500' : ''"
					class="tab px-4 py-2 hover:text-orange-400 transition-colors"
				>
					Memory
				</button>
			</div>
			<div
				v-for="(graph, index) in graphs"
				class="flex flex-col !list-none w-full text-gray-500 dark:text-gray-400 text-lg"
				:key="graph.title"
			>
				<GraphLine :lang="graph.lang" :title="graph.title" :value="tab == 0 ? graph.value : tab == 1 ? graph.latency : graph.memory" :label="label" :isFirst="index === 0" :max="max"/>
			</div>
			<p class="results text-gray-400 text-xs pb-1">Measurement in Request per Second, MB and Milliseconds. Results from <a href="https://sharkbench.dev/web" target="_blank">sharkbench.dev</a>.</p>
		</section>
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