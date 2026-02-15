<script setup lang="ts">
import { useRouter } from 'vitepress'
import { computed } from 'vue'
import { motion } from 'motion-v'
import { OpenInOption } from './data/spotlights'
import { ChatGptIcon, ClaudeIcon, MarkdownIcon } from './home/icons'

const props = defineProps<{
  className?: string,
  options?: Array<OpenInOption>
}>()

const { route } = useRouter()

const currentPageUrl = computed(
  () => `https://serinus.app${route.path.replace(/\.html$/, '')}.md`
)

const prompt = computed(() =>
  encodeURI(
    `I'm looking at ${currentPageUrl.value}.\n\nWould you kindly explain, summarize the concept, and answer any questions I have about it?`
  )
)

const defaultOptions = computed<Array<OpenInOption>>(() => [
  {
    name: 'ChatGPT',
    icon: ChatGptIcon,
    href: 'https://chatgpt.com/?prompt='
  },
  {
    name: 'Claude',
    icon: ClaudeIcon,
    href: 'https://claude.ai/new?q='
  },
  {
    name: 'Markdown',
    icon: MarkdownIcon,
    href: currentPageUrl.value
  }
])

const options = computed(() => props.options || defaultOptions.value)
</script>

<template>
  <motion.div
    :initial="{ opacity: 0, y: 10 }"
    :animate="{ opacity: 1, y: 0 }"
    :class="['inline-flex items-center gap-3 px-4 py-2 rounded-full bg-serinus-dark border border-border-imp fixed bottom-16 right-16', props.className]"
  >
    <span class="text-sm text-muted-foreground font-medium font-mono">Open in</span>

    <div class="flex items-center gap-1">
      <motion.a
        v-for="(option, index) in options"
        :key="option.name"
        :href="option.href.endsWith('=') ? option.href + prompt : option.href"
        :title="option.name"
        :whileHover="{ scale: 1.1 }"
        :whileTap="{ scale: 0.95 }"
        :initial="{ opacity: 0, x: -10 }"
        :animate="{ opacity: 1, x: 0 }"
        :transition="{ delay: index * 0.1 }"
        target="_blank"
        rel="noopener noreferrer"
        class="p-2 rounded-lg bg-background/10 hover:bg-serinus-yellow/20 hover:text-serinus-yellow text-foreground/70 transition-colors duration-200"
      >
        <component :is="option.icon" />
      </motion.a>
    </div>
  </motion.div>
</template>
