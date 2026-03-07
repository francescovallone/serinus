<script setup lang="ts">
import { motion, AnimatePresence } from 'motion-v';
import { computed, ref } from 'vue';
import { CopyIcon } from './icons';

interface CliSequenceStep {
	command: string;
}

const props = withDefaults(defineProps<{
	steps?: CliSequenceStep[];
	successMessage?: string;
	successLinkHref?: string;
	successLinkLabel?: string;
	classes?: string;
}>(), {
	successMessage: 'Congrats, you are good to go!',
	successLinkHref: 'https://serinus.app/introduction.html',
	successLinkLabel: 'Read the documentation',
	classes: 'max-w-2/3'
});

const defaultSteps: CliSequenceStep[] = [
	{ command: 'dart pub global activate serinus_cli' },
	{ command: 'serinus create example_app' },
];

const steps = computed(() => props.steps?.length ? props.steps : defaultSteps);
const lastStepIndex = computed(() => steps.value.length - 1);
const step = ref(0);
const copiedStep = ref<number | null>(null);
const visibleSteps = computed(() => steps.value.slice(0, Math.min(step.value + 1, steps.value.length)));

function copyAndAdvance(text: string) {
  navigator.clipboard.writeText(text);

	const currentStep = step.value;
	copiedStep.value = currentStep;
	setTimeout(() => {
		if (copiedStep.value === currentStep) {
			copiedStep.value = null;
		}
	}, 1500);

	if (step.value < steps.value.length) {
	setTimeout(() => (step.value += 1), 300);
  }
}
</script>

<template>
	<motion.div
		:initial="{ opacity: 0 }"
		:animate="{ opacity: 1 }"
		:transition="{ duration: 0.5, delay: 0.5 }"
		class="flex flex-col gap-2"
	>
		<div class="flex flex-col gap-2">
			<AnimatePresence>
				<motion.div
					v-for="(sequenceStep, index) in visibleSteps"
					:key="`${index}-${sequenceStep.command}`"
					:initial="index === 0 ? { opacity: 1 } : { opacity: 0, y: -10, height: 0 }"
					:animate="index === 0 ? { opacity: 1 } : { opacity: 1, y: 0, height: 'auto' }"
					:exit="{ opacity: 0, y: -10, height: 0 }"
					:transition="{ duration: index === 0 ? 0 : 0.3 }"
					@click="copyAndAdvance(sequenceStep.command)"
					:class="[
						'group flex cursor-pointer items-center gap-3 border border-border bg-card px-4 py-3 font-mono text-sm transition-colors hover:border-primary/50',
						classes
					]"
				>
					<svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 7l5 5l-5 5m7 2h7"/></svg>
					<span class="text-muted-foreground">$</span>
					<code class="text-foreground">{{ sequenceStep.command }}</code>
					<span class="ml-auto">
						<svg v-if="copiedStep === index" class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 12l5 5L20 7"/></svg>
						<CopyIcon v-else class="w-4 h-4 text-muted-foreground group-hover:text-primary transition-colors" />
					</span>
				</motion.div>
			</AnimatePresence>
			<AnimatePresence>
				<motion.div
					v-if="step > lastStepIndex"
					:initial="{ opacity: 0, y: -10, height: 0 }"
					:animate="{ opacity: 1, y: 0, height: 'auto' }"
					:exit="{ opacity: 0, y: -10, height: 0 }"
					:transition="{ duration: 0.3 }"
					:class="[
						'inline-flex items-center gap-3 px-4 py-3 bg-primary/10 border border-primary/30 font-mono text-sm',
						classes
					]"
				>
					<span class="text-primary">✓</span>
					<span class="text-foreground">
						{{ successMessage }}
						{{ ' ' }}
						<a
							:href="successLinkHref"
							target="_blank"
							rel="noopener noreferrer"
							class="text-primary underline hover:text-primary/80 transition-colors"
						>
							{{ successLinkLabel }}
						</a>
					</span>
				</motion.div>
			</AnimatePresence>
		</div>
	</motion.div>
</template>
<style scoped>
.border-border {
	border-color: hsl(var(--border));
}
</style>