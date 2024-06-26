<script setup>
const max = 6831;
const scale = (value) => (value / max) * 100
const scaleStyle = (value) =>
    `width: ${((value / max) * 100).toFixed(2)}%`
const scalePadding = (value) =>
    `padding-left: ${((value / max) * 100).toFixed(2)}%`
const format = new Intl.NumberFormat().format
const graphs = [
    {
		title: 'Express',
		lang: 'Node',
		value: 6799
	},
	{
		title: 'Nest',
		lang: 'Node',
		value: 	6352,
	},
	{
		title: 'Shelf',
		lang: 'Dart',
		value: 6311
	},
	{
		title: 'Dart Frog',
		lang: 'Dart',
		value: 5875
	},
	{
		title: 'Django',
		lang: 'Python',
		value: 949
	}
]

</script>

<template>
	<div class="container flex w-full gap-8 lg:flex-row flex-col my-8">
		<section class="flex flex-col gap-6 flex-1">
			<h1 class="text-2xl font-bold">Fast 🚀</h1>
			<p class="text-xl text-gray-400">
				Serinus is designed to be fast and efficient. It is built on top of the Dart language, which is known for its performance and efficiency.
			</p>
			<p class="text-xl text-gray-400">
				Here are some benchmarks comparing Serinus with other popular frameworks.
			</p>
		</section>
		<section class="flex flex-col gap-4 flex-1">
			<ol
                class="flex flex-col list-none w-full text-gray-500 dark:text-gray-400 text-lg"
            >
                <li class="flex flex-row items-stretch w-full gap-4">
                    <p
                        class="flex items-end gap-2 w-full max-w-[8em] dark:text-gray-400"
                    >
                        Serinus
                        <span class="text-gray-400 text-xs pb-1"> Dart </span>
                    </p>
                    <div class="w-full h-7 relative">
                        <div
                            class="flex justify-end items-center text-sm font-bold text-white h-7 px-2.5 py-0.5 bg-gradient-to-r from-yellow-400 to-orange-500 rounded-full"
                        >
                            {{ format(max) }} req/s
                        </div>
                    </div>
                </li>
                <li
                    v-for="graph in graphs"
                    class="flex flex-row w-full gap-4"
					:key="graph.title"
                >
                    <p
                        class="flex items-end gap-2 w-full max-w-[8em] dark:text-gray-400"
                    >
                        {{ graph.title }}
                        <span class="text-gray-400 text-xs pb-1">
                            {{ graph.lang }}
                        </span>
                    </p>
                    <div class="w-full h-7 relative">
                        <div
                            class="flex justify-end items-center text-sm px-2.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded-full mr-auto h-7"
                            :style="scaleStyle(graph.value)"
                        >
                            <span
                                v-if="scale(graph.value) > 40"
                                class="absolute z-1 flex items-center text-sm h-7"
                            >
                                {{ format(graph.value) }}
                            </span>
                        </div>
                        <span
                            v-if="scale(graph.value) <= 40"
                            class="absolute top-0 flex items-center text-sm h-7 left-2"
                            :style="scalePadding(graph.value)"
                        >
                            {{ format(graph.value) }}
                        </span>
                    </div>
                </li>
            </ol>
			<p class="results text-gray-400 text-xs pb-1">Measurement in Requests per Second. Results from <a href="https://sharkbench.dev/web" target="_blank">sharkbench.dev</a>.</p>
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