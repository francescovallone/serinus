<script setup>
import Ecosystem from './ecosystem.vue'
import Hero from './hero.vue'
import Partners from './partners.vue'
import Highlights from './highlights.vue'
import Features from './features.vue'
import Spotlights from './spotlight.vue'
import { plugins } from './data/ecosystem';
</script>

<template>
	<div class="flex flex-col gap-16">
		<Hero>
			<slot name="start"></slot>
		</Hero>
		<Highlights />
		<Ecosystem>
			<template #openapi>
				<slot name="openapi"></slot>
			</template>
			<template #configuration>
				<slot name="configuration"></slot>
			</template>
			<template #authentication>
				<slot name="authentication"></slot>
			</template>
			<template #cron_jobs>
				<slot name="cron_jobs"></slot>
			</template>
			<template #websockets>
				<slot name="websockets"></slot>
			</template>
			<template #testing>
				<slot name="testing"></slot>
			</template>
		</Ecosystem>
		<Spotlights />
	</div>
</template>

<style scoped>
.VPNavBar {
	background-color: transparent !important;
}
</style>