<script lang="ts" setup>
import { defineProps, onMounted, onUnmounted, ref } from 'vue'
import { authors, Authors } from './data/blog'
import ShareRow from './share_row.vue'

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
    console.log(props.tags)
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

</script>

<template>
    <article id="blog" class="flex flex-col max-w-5xl w-full mx-auto mt-8">
        <div class="flex items-center gap-4 mb-4 justify-between">
            <div @click="goBack()" class="cursor-pointer text-serinus hover:underline m-0 flex items-center gap-2 text-xs font-medium tracking-wide uppercase">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
                Back
            </div>
            <div class="flex flex-wrap gap-2">
                <p v-for="tag in props.tags" :key="tag" style="margin-bottom: 0; line-height: 1rem;" class="flex gap-2 m-0 text-xs font-medium tracking-wide uppercase max-w-fit rounded-lg">
                    {{ tag }}
                </p>
            </div>
        </div>
        <h1 class="text-5xl font-medium">
            {{ props.title }}
        </h1>
        <div class="flex gap-3 mt-4 justify-between">
            <div class="flex gap-3">
                <img
                    class="w-9 h-9 rounded-full"
                    :src="profile"
                    :alt="props.author"
                />
                <div class="flex flex-col justify-start">
                    <h3 class="!text-sm !m-0 opacity-75">{{ props.author }}</h3>
                    <p class="flex flex-row items-center gap-2 !text-xs !m-0 opacity-75 relative">
                        <span>{{ props.date }}</span>
                        <span>ー</span>
                        <a :href="x" target="_blank">@{{ author.twitter }}</a>
                    </p>
                </div>
            </div>
            <div class="!text-xs !m-0 opacity-75 flex flex-col items-end gap-1">
                <div><span class="font-bold">{{ readingTime }}</span> min read</div>
                <div v-if="props.lastUpdated">Last updated: <span class="font-bold">{{ lastUpdated }}</span></div>
            </div>
        </div>
        <img :src="props.src" :alt="props.alt" class="w-full mt-6 mb-2" :class="props.shadow ? 'shadow-xl' : 'border'" />
        <main id="blog-content">
            <slot key="blog-content" />
        </main>
        <ShareRow />
    </article>
</template>

<style lang="css" scoped>
.tag {
	background-color: var(--vp-c-brand-darker);
}
</style>

<style>
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

#blog>img {
    @apply rounded-lg;
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

#blog-content>video,
#blog-content>*>video,
#blog-content>img,
#blog-content>*>img {
    @apply rounded-xl my-4;
    /* box-shadow: 0 8px 25px rgba(0,0,0,.1) */
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
