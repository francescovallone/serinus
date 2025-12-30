<script lang="ts" setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { authors, Authors } from '../data/blog'
import ShareRow from '../share_row.vue'
import { CalendarIcon } from '../home/icons';

const props = defineProps<{
    title: string
    src: string
    alt: string
    author: keyof Authors
    date: string
    shadow?: boolean
    tags: string[],
    lastUpdated: string
}>()

const author = authors[props.author]
const profile = `/blog/authors/${author.src}`
const x = `https://x.com/${author.twitter}`
const WPM = 238

const readingTime = ref('0')

const mutated = ['.aside', '.content', '.content-container', '.VPDocFooter']
onMounted(() => {
    mutated.forEach((selector) => {
        document.querySelector(selector)?.classList.add('blog')
    })
    readingTime.value = calculateReadingTime(document.querySelector('#blog-content')?.textContent || '')
})

function goBack() {
    history.back()
}

onUnmounted(() => {
    mutated.forEach((selector) => {
        document.querySelector(selector)?.classList.remove('blog')
    })
})

function calculateReadingTime(text: string): string {
  const words = text.trim().split(/\s+/).length;
  return (words / WPM).toFixed(1);
}

const categoryColors: Record<string, string> = {
  releases: "bg-primary text-primary-foreground",
  tutorial: "bg-emerald-500 text-white",
  general: "bg-foreground text-background",
};

</script>

<template>
    <article id="blog" class="flex flex-col max-w-5xl w-full mx-auto mt-8">
        <div class="flex items-center gap-4 mb-4 justify-between">
            <a href="/blog" class="text-primary no-underline! m-0 group inline-flex items-center gap-2 text-xs font-medium tracking-wider font-mono uppercase hover:gap-5 transition-all!">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
                Blog
            </a>
            <div class="inline-flex gap-2 items-center justify-center">
                <div class="text-sm inline-flex items-center gap-1 text-muted-foreground">
                    <CalendarIcon class="w-1 h-1" />
                    <span class="text-xs uppercase font-mono">{{ props.date }}</span>
                </div>
                <p v-for="tag in props.tags" :key="tag" style="margin-bottom: 0; line-height: 1rem;" :class="`tag m-0! ${categoryColors[tag] || ''}`">
                    {{ tag }}
                </p>
            </div>
        </div>
        <div v-if="props.title.includes('-')" class="text-5xl font-display font-bold">
            {{ props.title.split('-')[0] }} -
            <span class="font-serif italic font-normal text-muted-foreground">
                {{ props.title.split('-').slice(1).join('-') }}
            </span>
        </div>
        <div v-else class="text-5xl md:text-6xl lg:text-7xl font-display font-bold">
            {{ props.title }}
        </div>
        <div class="flex gap-3 mt-4 justify-between">
            <div class="flex gap-3">
                <img
                    class="w-9 h-9 rounded-full"
                    :src="profile"
                    :alt="props.author"
                />
                <div class="flex flex-col justify-start">
                    <h3 class="!text-sm !m-0 opacity-75">{{ props.author }}</h3>
                    <p class="flex flex-row items-center gap-1 !text-xs !m-0 opacity-75 relative">
                        <a :href="x" target="_blank" class="no-underline!">@{{ author.twitter }}</a>
                    </p>
                </div>
            </div>
            <div class="!text-xs !m-0 opacity-75 flex flex-col items-end gap-1">
                <div><span class="font-bold font-display">{{ readingTime }}</span> min read</div>
                <div v-if="props.lastUpdated">Last updated: <span class="font-bold font-display">{{ lastUpdated }}</span></div>
            </div>
        </div>
        <img :src="props.src" :alt="props.alt" class="w-full mt-6 mb-2" :class="props.shadow ? 'shadow-xl' : 'border'" />
        <main id="blog-content">
            <slot key="blog-content" />
        </main>
        <ShareRow />
    </article>
</template>

<style>

@reference "tailwindcss";

.blog.aside {
    position: fixed !important;
    z-index: 10;
    left: calc(50% + 48rem / 2 + 2rem) !important;
}

.blog.content,
.blog.content-container {
    max-width: unset !important;
}

.blog.VPDocFooter {
    display: none !important;
}

#blog {
    @apply text-lg mt-0;
}

#blog>h1 {
    @apply !text-3xl md:!text-4xl font-semibold;
}

#blog>h2 {
    @apply !text-2xl md:!text-3xl font-semibold;
}

#blog>h3 {
    @apply !text-xl md:!text-2xl font-semibold;
}

.-png {
    box-shadow: unset !important;
    background: transparent !important;
}

@media (min-width: 768px) {
    #blog>h1 {
        line-height: 3.25rem !important;
    }
}
</style>
