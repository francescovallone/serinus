<script setup lang="ts">
import { motion, AnimatePresence } from 'motion-v';
import { ref } from 'vue';
import { CopyIcon } from './icons';

const step = ref(0);
const copied = ref(false);
function copyAndAdvance(text: string) {
  navigator.clipboard.writeText(text);
  copied.value = true;
  setTimeout(() => (copied.value = false), 1500);
  if (step.value < 2) {
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
		<!-- Step 1: Install CLI -->
		<div
			@click="copyAndAdvance('dart pub global activate serinus_cli')"
			class="group inline-flex items-center gap-3 px-4 py-3 bg-card border border-border font-mono text-sm cursor-pointer hover:border-primary/50 transition-colors"
		>
			<svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 7l5 5l-5 5m7 2h7"/></svg>
			<span class="text-muted-foreground">$</span>
			<code class="text-foreground">dart pub global activate serinus_cli</code>
			<span class="ml-auto">
				<svg v-if="copied && step === 0" class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 12l5 5L20 7"/></svg>
				<CopyIcon v-else class="w-4 h-4 text-muted-foreground group-hover:text-primary transition-colors" />
			</span>
		</div>
		<!-- Step 2: Create App -->
		<AnimatePresence>
			<motion.div
				v-if="step >= 1"
				:initial="{ opacity: 0, y: -10, height: 0 }"
				:animate="{ opacity: 1, y: 0, height: 'auto' }"
				:exit="{ opacity: 0, y: -10, height: 0 }"
				:transition="{ duration: 0.3 }"
				@click="copyAndAdvance('serinus create example_app')"
				class="group inline-flex items-center gap-3 px-4 py-3 bg-card border border-border font-mono text-sm cursor-pointer hover:border-primary/50 transition-colors"
			>
				<svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 7l5 5l-5 5m7 2h7"/></svg>
				<span class="text-muted-foreground">$</span>
				<code class="text-foreground">serinus create example_app</code>
				<span class="ml-auto">
					<svg v-if="copied && step === 1" class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 12l5 5L20 7"/></svg>
					<CopyIcon v-else class="w-4 h-4 text-muted-foreground group-hover:text-primary transition-colors" />
				</span>
			</motion.div>
		</AnimatePresence>
		<!-- Step 3: Success Message -->
		<AnimatePresence>
			<motion.div
				v-if="step >= 2"
				:initial="{ opacity: 0, y: -10, height: 0 }"
				:animate="{ opacity: 1, y: 0, height: 'auto' }"
				:exit="{ opacity: 0, y: -10, height: 0 }"
				:transition="{ duration: 0.3 }"
				class="inline-flex items-center gap-3 px-4 py-3 bg-primary/10 border border-primary/30 font-mono text-sm"
			>
				<span class="text-primary">✓</span>
				<span class="text-foreground">
					Congrats, you are good to go! 
					<a
						href="https://serinus.app/introduction.html"
						target="_blank"
						rel="noopener noreferrer"
						class="text-primary underline hover:text-primary/80 transition-colors"
					>
						Read the documentation
					</a>
				</span>
			</motion.div>
		</AnimatePresence>
	</motion.div>
</template>