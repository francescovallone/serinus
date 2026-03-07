<script setup lang="ts">
import { motion } from 'motion-v';
import { scrollVariants } from '../actions/scroll_variants';
import { BrainIcon, BracesFile, MarkdownIcon } from './icons';
import CliSequence from './cli_sequence.vue';
import { ref } from 'vue';

const currentFeature = ref(0);

const features = [
  {
    icon: MarkdownIcon,
    title: 'AGENTS.md',
    description: "Generate a comprehensive AGENTS.md (or CLAUDE.md) file for your team, detailing Serinus capabilities, best practices, and example patterns for your use case.",
    tag: 'Documentation',
	command: 'serinus agents'
  },
  {
    icon: BrainIcon,
    title: 'Skills',
    description: 'Generate all the skills needed to develop your applications, from a minimal application to a fully modular application connected to microservices.',
    tag: 'Skill Generation',
	command: 'skills get'
  },
  {
    icon: BracesFile,
    title: 'llms.txt',
    description: 'Serinus website ships with a llms.txt, making it extremely AI-friendly and providing a single source of truth for all LLM-related information about Serinus.',
    tag: 'LLM Reference',
  },
];
</script>

<template>
  <section class="relative border-border py-20 md:py-28">
	<div class="absolute top-20 right-10 text-[150px] font-display font-bold text-stroke opacity-5 select-none hidden lg:block">
      03
    </div>
    <div class="container mx-auto px-6">
      <div class="space-y-16">
		<div class="grid lg:grid-cols-12 gap-8 mb-20">
          <motion.div
            :variants="scrollVariants.slideLeft"
            initial="hidden"
            whileInView="visible"
            :inViewOptions="{ once: true, amount: 0.3 }"
            :transition="{ duration: 0.6 }"
            class="lg:col-span-4"
          >
        	<div class="mb-6 flex items-center gap-3">
				<BrainIcon class="h-5 w-5 text-primary" />
				<p class="tag text-primary">AI-Ready</p>
			</div>
            <div class="text-4xl md:text-5xl font-display font-bold leading-tight">
              Built for the
              <br />
              <span class="font-serif italic font-normal text-muted-foreground">agentic era</span>
            </div>
          </motion.div>
          
          <motion.div
            :variants="scrollVariants.slideRight"
            initial="hidden"
            whileInView="visible"
            :inViewOptions="{ once: true, amount: 0.3 }"
            :transition="{ duration: 0.6, delay: 0.2 }"
            class="lg:col-span-5 lg:col-start-7 flex items-end"
          >
            <p class="text-lg text-muted-foreground leading-relaxed">
               	Serinus provides the files AI agents and LLMs need to understand,
        		discover, and interact with your application.
            </p>
          </motion.div>
        </div>
        
        <div class="grid gap-6 md:grid-cols-3">
          <motion.div
            v-for="(feature, index) in features"
            :key="feature.title"
            :variants="scrollVariants.scaleIn"
            initial="hidden"
            whileInView="visible"
			@click="currentFeature = index"
            :inViewOptions="{ once: true, amount: 0.2 }"
            :transition="{ duration: 0.45, delay: index * 0.1 }"
            :class="[
				'group border-2 border-border bg-card p-8 transition-colors hover:!border-primary/50',
				currentFeature === index ? '!border-primary bg-primary/5' : ''
			]"
          >
            <div class="mb-6 flex items-start justify-between gap-4">
              <div class="border border-primary/20 bg-primary/10 p-3">
                <component :is="feature.icon" class="h-5 w-5 text-primary" />
              </div>
              <span class="rounded bg-muted px-2 py-1 font-mono text-[10px] uppercase tracking-wider text-muted-foreground">
                {{ feature.tag }}
              </span>
            </div>

            <h3 class="mb-3 font-mono text-xl font-bold tracking-tight text-foreground">
              {{ feature.title }}
            </h3>
            <p class="text-sm leading-relaxed text-muted-foreground">
              {{ feature.description }}
            </p>
          </motion.div>
        </div>
		<div class="block max-w-1/2" style="margin: 0 auto">
			<CliSequence v-if="features[currentFeature].command" :steps="[{ command: (features[currentFeature].command ?? '') }]" success-message="Command copied to clipboard!" classes="w-full" />
		</div>
      </div>
    </div>
  </section>
</template>

<style scoped>
p {
  margin: 0 !important;
}
.border-border {
  border-color: hsl(var(--border));
}
</style>