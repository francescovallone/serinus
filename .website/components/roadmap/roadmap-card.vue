<script setup lang="ts">
import { motion } from 'motion-v';
import { type RoadmapItem, type RoadmapStatus } from '../data/tracks';
	const props = defineProps<{
		item: RoadmapItem,
		trackColor: string
	}>();
import { CheckIcon } from '../home/icons';
const statusConfig: Record<RoadmapStatus, { label: string; icon: any; class: string }> = {
  done: { label: "Done", icon: CheckIcon, class: "bg-primary/15 text-primary border-primary/30" },
  "in-progress": { label: "In Progress", icon: CheckIcon, class: "bg-accent/10 text-accent border-accent/30" },
  planned: { label: "Planned", icon: CheckIcon, class: "bg-muted text-muted-foreground border-border" },
};

const config = statusConfig[props.item.status];
</script>
<template>
	<motion.div
		layout="position"
		:initial="{ opacity: 0, y: 12 }"
		:animate="{ opacity: 1, y: 0 }"
		:exit="{ opacity: 0, y: -8 }"
		:transition="{ duration: 0.2 }"
		:class="[
			'group relative p-4 rounded-lg border transition-shadow duration-200 hover:shadow-md',
			config.class
		]"
	>
		<div class="flex items-center justify-between gap-3">
			<div class="flex-1 min-w-0">
				<div class="flex items-center gap-2 mb-1">
					<component :is="config.icon" class="w-3.5 h-3.5 shrink-0" />
					<a :href="props.item.githubIssueUrl" class="text-sm font-display font-semibold truncate">{{ props.item.title }}</a>
				</div>
				<div v-if="props.item.description" class="text-xs text-muted-foreground mt-1 line-clamp-2">
					{{ props.item.description }}
				</div>
			</div>
			<span
			 	v-if="props.item.version"
				class="shrink-0 text-[10px] font-mono px-2 py-0.5 rounded-full border"
				:style="{
					borderColor: `hsl(${props.trackColor} / 0.4)`,
					color: `hsl(${props.trackColor})`,
					backgroundColor: `hsl(${props.trackColor} / 0.08)`,
				}"
			> 
				{{ props.item.version }}
			</span>
		</div>	
	</motion.div>
</template>