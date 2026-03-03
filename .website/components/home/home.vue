<script setup>
import Ecosystem from './ecosystem.vue'
import Hero from './hero.vue'
import Features from './features.vue'
import CommunitySection from './community_section.vue'
</script>

<template>
	<div class="flex flex-col">
		<Hero>
			<slot name="start"></slot>
		</Hero>
		<Features />
		<Ecosystem>
			<template #openapi>
				<slot name="openapi"></slot>
			</template>
			<template #database>
				<slot name="database"></slot>
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
		<CommunitySection />
	</div>
</template>

<style scoped>
.VPNavBar {
	background-color: transparent !important;
}
</style>