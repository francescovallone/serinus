<script setup lang="ts">
import { type RoadmapTrack } from '../data/tracks';
import { ChevronRight } from '../home/icons';

defineProps<{
	track: RoadmapTrack,
	isActive: boolean,
	click: () => void
}>();
</script>

<template>
	<div
		@click="() => click()"
		:class="[
			'w-full text-left p-4 rounded-lg border transition-all duration-200 cursor-pointer select-none',
			isActive ? 'border-primary/40 bg-primary/5' : 'border-transparent hover-border-border hover:bg-card/50'
		]"
	>
		<div class="flex items-center justify-between">
			<div class="flex items-center gap-2">
				<div
					class="w-2.5 h-2.5 rounded-full"
					:style="{
						backgroundColor: `hsl(${track.color} / 1)`,
					}"
				></div>
				<span class="text-sm font-display font-semibold text-foreground">{{ track.label }}</span>
				<span v-if="track.wip" class="text-xs font-mono text-primary">
					[ WIP ]
				</span>
			</div>
			<ChevronRight
				:class="[
					'w-4 h-4 text-muted-foreground transition-transform',
					isActive ? 'rotate-90 text-primary' : ''
				]"
			>
			</ChevronRight>
		</div>
	</div>
</template>
<style scoped>
.hover-border-border:hover {
	border-color: hsl(var(--border));
}
</style>