<script setup>
import Ecosystem from './ecosystem.vue'
import Hero from './hero.vue'
import Partners from './partners.vue'
import Highlights from './highlights.vue'
import Features from './features.vue'
import { spotlights } from './data/spotlights'
import Spotlights from './spotlight.vue'
import Cli from './cli.vue'
</script>

<template>
	<div class="flex flex-col gap-16">
		<Hero>
			<slot name="start"></slot>
		</Hero>
		<Highlights />
		<Ecosystem>
			<slot name="configuration" slot="configuration"></slot>
			<slot name="openapi" slot="openapi"></slot>
			<slot name="authentication" slot="authentication"></slot>
			<slot name="cron_jobs" slot="cron_jobs"></slot>
		</Ecosystem>
		<Spotlights />
	</div>
</template>

<style scoped>
.VPNavBar {
	background-color: transparent !important;
}
</style>