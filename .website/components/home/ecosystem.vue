<script setup>
import { ref } from 'vue';
import { plugins } from '../data/ecosystem.ts';
import dropdown from '../dropdown.vue';

const currentPlugin = ref(plugins[0]);

const changePlugin = (selectedPlugin, event) => {
  if (event?.currentTarget) {
    event.currentTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
  }
  if (selectedPlugin) {
    currentPlugin.value = selectedPlugin;
  }
};

</script>

<template>
	<section class="py-32 bg-card/50 relative overflow-hidden grain">
      <div class="absolute top-20 right-10 text-[150px] font-display font-bold text-stroke opacity-5 select-none hidden lg:block">
        03
      </div>

      <div class="container mx-auto px-6">
        <motion.div
          variants={scrollVariants.fadeUp}
          initial="hidden"
          whileInView="visible"
          :inViewOptions="{ once: true, amount: 0.3 }"
          :transition="{ duration: 0.6 }"
          class="max-w-2xl mb-16"
        >
          <span class="tag text-muted-foreground mb-4 block w-fit">Ecosystem</span>
          <div class="text-4xl md:text-5xl font-display font-bold leading-tight mb-4">
            Everything you need,
            <br />
            <span class="font-serif italic font-normal text-muted-foreground">nothing you don't</span>
          </div>
        </motion.div>

        <div class="grid lg:grid-cols-12 gap-8">
          <div class="lg:hidden">
            <dropdown>
              <template #trigger>
                <div class="flex gap-2">
                  <component :is="currentPlugin.icon" class="flex-shrink-0 group-hover:text-foreground" />
                  <div>
                    <span class="font-display font-normal block">{{currentPlugin.title}}</span>
                  </div>
                </div>
              </template>
              <template #default>
                <div
                  :key="item.id"
                  v-for="item in plugins"
                  @click="() => changePlugin(item)"
                  :class="`group flex items-center gap-4 px-5 py-4 cursor-pointer text-left transition-all border-2 ${currentPlugin.title === item.title ? 'border-primary bg-primary/5 text-foreground' : 'border-transparent bg-background text-muted-foreground hover:text-foreground hover:border-border'}`"
                >
                  <component :is="item.icon" :class="currentPlugin.title === item.title ? 'text-primary flex-shrink-0' : 'text-muted-foreground flex-shrink-0 group-hover:text-foreground'" />
                  <div>
                    <span class="font-display font-semibold block">{{item.title}}</span>
                    <span class="text-xs text-muted-foreground hidden lg:block">{{item.desc}}</span>
                  </div>
                </div>
              </template>
            </dropdown>
          </div>
          <div class="lg:col-span-4 flex-wrap lg:flex-col gap-2 hidden lg:flex">
            <div
                :key="item.id"
			          v-for="item in plugins"
		            @click="(event) => changePlugin(item, event)"
                :class="`group flex items-center gap-4 px-5 py-4 cursor-pointer text-left transition-all border-2 ${currentPlugin.title === item.title ? 'border-primary bg-primary/5 text-foreground' : 'border-transparent bg-background text-muted-foreground hover:text-foreground hover:border-border'}`"
              >
                <component :is="item.icon" :class="currentPlugin.title === item.title ? 'text-primary flex-shrink-0' : 'text-muted-foreground flex-shrink-0 group-hover:text-foreground'" />
                <div>
                  <span class="font-display font-semibold block">{{item.title}}</span>
                  <span class="text-xs text-muted-foreground hidden lg:block">{{item.desc}}</span>
                </div>
            </div>
          </div>
          

          <motion.div
            :key="currentPlugin.title"
            :initial="{ opacity: 0, x: 20 }"
            :animate="{ opacity: 1, x: 0 }"
            :transition="{ duration: 0.3 }"
            class="lg:col-span-8 flex flex-col gap-4 code-limiter"
          >
		  	    <slot :name="currentPlugin.slot" :slot="currentPlugin.slot"></slot>
            <a :href="currentPlugin.link" class="inline-flex items-center gap-2 text-sm text-muted-foreground! hover:text-primary! transition-colors group">
              <span>Read the documentation</span>
              <span class="group-hover:translate-x-1 transition-transform">→</span>
            </a>
          </motion.div>
        </div>
      </div>
    </section>
</template>

<style scoped>
.vp-doc p, .vp-doc summary {
	margin: 0 !important;
}
.results{
	line-height: 1rem;
}
ol {
	padding: 0;
}
.vp-doc a{
	text-decoration: none;
}
.vp-doc a.bg-orange-400 {
	color: white;
}
</style>
<style>
@reference "tailwindcss";
.code-limiter {
  max-width: calc(100vw - calc(var(--spacing) * 12));
}
@media (width >= 48rem) {
  .code-limiter {
    max-width: none;
  }
}
.tabs::-webkit-scrollbar {
  display: none;
}
.tabs {
	scrollbar-width: none;
	-ms-overflow-style: none;
}
.display h3 {
	@apply text-lg font-semibold text-pretty;
}
.display p {
	@apply text-base text-gray-500 my-4;
}
.display p .numbered {
	@apply font-bold pr-4;
}
</style>