<script setup>
import { computed, ref } from 'vue';
import { roadmapTracks } from '../data/tracks';
import TrackSidebarItem from './track-sidebar-item.vue';
import RoadmapCard from './roadmap-card.vue';

const activeTrackId = ref(null);

const visibleTracks = computed(() => {
  if (!activeTrackId.value) {
    return roadmapTracks;
  }
  return roadmapTracks.filter((track) => track.id === activeTrackId.value);
});

const statuses = ['done', 'in-progress', 'planned'];

const statusConfig = {
  done: { label: 'Done' },
  'in-progress': { label: 'In Progress' },
  planned: { label: 'Planned' },
};

const itemsByStatus = (track, status) =>
  track.items.filter((item) => item.status === status);

</script>
<template>
	<div class="min-h-screen bg-background grain">
		<div class="flex w-full">
			<aside class="hidden lg:block w-72 shrink-0 border-r border-border">
				<div class="sticky top-24 h-[calc(100vh-6rem)] overflow-y-auto p-6">
					<div class="font-display font-bold text-foreground text-lg mb-1">Roadmap</div>
					<div class="text-xs text-muted-foreground mb-6">Track progress of upcoming features and improvements</div>
					<div class="space-y-1">
						<div
							@click="activeTrackId = null"
							:class="[
								'w-full text-left px-4 py-2 rounded-lg text-sm font-display font-medium transition-colors cursor-pointer select-none',
								activeTrackId === null ? 'bg-primary/10 text-primary' : 'text-muted-foreground hover:text-foreground'
							]"
						>
							All tracks
						</div>
						<TrackSidebarItem
							v-for="track in roadmapTracks"
							:key="track.id"
							:track="track"
							:isActive="activeTrackId === track.id"
							:click="() => activeTrackId = track.id"
						/>
					</div>
				</div>
			</aside>
			<main class="flex-1 min-w-0">
				<div class="border-b border-border bg-background/80 backdrop-blur-md">
					<div class="container mx-auto px-6 py-8 max-w-5xl">
						<span class="tag text-muted-foreground mb-4 inline-block">Roadmap</span>
						<div class="text-4xl md:text-5xl font-display font-bold tracking-tight">
							What we're building
						</div>
						<div class="mt-3 text-muted-foreground max-w-xl">
							Follow the progress of Serinus core and its first-party plugins.
						</div>

						<div class="flex gap-2 mt-6 overflow-x-auto pb-2 lg:hidden">
							<div
							@click="activeTrackId = null"
							:class="[
								'shrink-0 px-3 py-1.5 rounded-full text-xs font-display font-semibold border transition-colors',
								activeTrackId === null
								? 'border-primary bg-primary/10 text-primary'
								: 'border-border text-muted-foreground'
							]"
							>
							All
							</div>
							<div
							v-for="track in roadmapTracks"
							:key="track.id"
							@click="activeTrackId = activeTrackId === track.id ? null : track.id"
							:class="[
								'shrink-0 px-3 py-1.5 rounded-full text-xs font-display font-semibold border transition-colors',
								activeTrackId === track.id
								? 'border-primary bg-primary/10 text-primary'
								: 'border-border text-muted-foreground'
							]"
							>
							{{ track.label }}
							</div>
						</div>
					</div>
				</div>

				<div class="container mx-auto px-6 py-10 max-w-5xl">
					<div class="space-y-12">
						<section v-for="track in visibleTracks" :key="track.id">
							<div class="flex items-center gap-3 mb-5">
								<div
									class="w-3 h-3 rounded-full"
									:style="{ backgroundColor: `hsl(${track.color})` }"
								></div>
								<div class="text-xl font-display font-bold text-foreground">
									{{ track.label }}
								</div>
								<span class="text-xs font-mono text-muted-foreground ml-auto">
									{{ track.progress }}% complete
								</span>
							</div>

							<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
							<div v-for="status in statuses" :key="status">
								<div class="flex items-center gap-2 mb-3 pb-2 border-b border-border">
									<span class="text-xs font-mono uppercase tracking-wider text-muted-foreground">
										{{ statusConfig[status].label }}
									</span>
									<span class="text-xs font-mono text-muted-foreground ml-auto">
										{{ itemsByStatus(track, status).length }}
									</span>
								</div>
								<div class="space-y-2">
									<RoadmapCard
										v-for="item in itemsByStatus(track, status)"
										:key="item.id"
										:item="item"
										:track-color="track.color"
									/>
									<p
										v-if="itemsByStatus(track, status).length === 0"
										class="text-xs text-muted-foreground italic py-4 text-center"
									>
										No items
									</p>
								</div>
							</div>
							</div>
						</section>
					</div>
				</div>
			</main>
		</div>
	</div>
</template>
<style scoped>
.border-border {
	border-color: hsl(var(--border));
}
</style>