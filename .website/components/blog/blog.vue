<script setup lang="ts">
import { computed, ref } from 'vue'
import { motion } from 'motion-v';
import { Post } from '../data/blog';
import { ArrowUpRightIcon, CalendarIcon } from '../home/icons';

const props = defineProps({
    posts: Array<Post>,
	title: String,
	desc: String,
	blog: Boolean,
	tags: Array<string>
})

const currentTopic = ref('')

function changeTopic(topic: string) {
	currentTopic.value = topic
}

const filteredPosts = computed(() => {
	if (currentTopic.value === '') {
		return props.posts
	}
	return props.posts?.filter((post) => post.tags.includes(currentTopic.value)) ?? []
})

const topics = computed(() => {
	const tags:string[] = []
	props.posts?.forEach((post) => {
		post.tags.forEach((tag) => {
			if (!tags.includes(tag)) {
				tags.push(tag)
			}
		})
	})
	return tags
})

const featuredPost = computed<Post | undefined>(() => {
	if (props.blog === false) {
		return undefined
	}
	return filteredPosts.value?.[0]
})

const otherPosts = computed<Post[]>(() => {
	return filteredPosts.value?.filter((post) => post.title !== featuredPost.value?.title) ?? []
})

const categoryColors: Record<string, string> = {
  releases: "bg-primary text-primary-foreground",
  tutorial: "bg-emerald-500 text-white",
  general: "bg-foreground text-background",
};

</script>

<template>
	<div class="min-h-screen bg-background grain">
		<main class="pt-32 pb-20">
          <div class="container mx-auto px-6">
            <motion.div
              :initial="{ opacity: 0, y: 20 }"
              :animate="{ opacity: 1, y: 0 }"
              class="mb-12"
            >
              <div class="flex items-end justify-between flex-wrap gap-4">
                <div>
                  <span class="tag text-muted-foreground mb-4 block w-fit">{{ props.blog === false ? 'Analysis' : 'Blog' }}</span>
                  <div class="text-5xl md:text-6xl lg:text-7xl font-display font-bold">
                    Latest <span class="font-serif italic font-normal text-muted-foreground">writings</span>
                  </div>
                </div>
                
                <div class="flex flex-wrap gap-2">
                  <div
					v-for="category in ['', ...topics]"
                      :key="category"
                      @click="() => changeTopic(category)"
                      :class='`px-4 py-2 font-display capitalize cursor-pointer font-medium text-sm transition-all border-2 ${
                        currentTopic === category
                          ? "border-primary bg-primary text-primary-foreground"
                          : "border-border text-muted-foreground hover:text-foreground hover:border-foreground"
                      }`'
                    >
                      {{ category === "" ? "All" : category }}
                    </div>
                </div>
              </div>
            </motion.div>
			  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              	<motion.a
				  v-for="(post, index) in otherPosts"
                  :key="post.title"
                  :href="post.href"
                  target="_blank"
                  rel="noopener noreferrer"
                  :initial="{ opacity: 0, y: 20 }"
                  :animate="{ opacity: 1, y: 0 }"
                  :transition="{ duration: 0.4, delay: 0.15 + index * 0.05 }"
                  class="group flex flex-col border-2 border-border bg-card/20 hover:border-primary hover:bg-card/40 transition-all overflow-hidden"
                >
                  <div class="aspect-video overflow-hidden" v-if="post.src">
                    <img 
                      :src="post.src"
                      :alt="post.title"
                      class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                  </div>
                  
                  <div class="p-6 flex flex-col flex-grow">
                    <div class="flex items-center justify-between mb-4">
                      <span v-if="post.tags.length > 0" :class='`tag text-[10px] ${categoryColors[post.tags[0]]}`'>
                        {{post.tags[0]}}
                      </span>
					  <span v-else></span>
                      <ArrowUpRightIcon class="w-5 h-5 text-muted-foreground group-hover:text-primary group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
                    </div>
                    
                    <div class="text-xl font-display font-semibold text-foreground group-hover:text-primary transition-colors mb-3 flex-grow">
                      {{post.title}}
                    </div>

					<p className="text-sm text-muted-foreground! mb-4! line-clamp-2">
                        {{post.desc}}
                    </p>
                    
                    <span class="font-mono text-xs text-muted-foreground mt-auto">
                      {{post.date}}
                    </span>
                  </div>
                </motion.a>
            </div>
			</div>
		</main>
	</div>
    
</template>
