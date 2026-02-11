<script setup lang="ts">
  import { motion } from 'motion-v';
  import { scrollVariants } from '../actions/scroll_variants';
  import { CodeFile, LightningIcon, PuzzleIcon, RadioIcon, SettingsIcon, ShieldIcon } from './icons';

  const features: any[] = [
    {
      number: '01',
      title: 'Just Return',
      description: 'Return anything from handlers: Strings, Maps, Lists, Streams, Files, Futures. Zero boilerplate.',
      icon: LightningIcon,
    },
    {
      number: '02',
      title: 'Specialized Tools',
      description: 'Hooks, Exception Filters, and Pipes. Full control over your application flow.',
      icon: SettingsIcon,
    },
    {
      number: '03',
      title: 'Real-time Ready',
      description: 'WebSockets and SSE built-in. Push updates instantly with zero config.',
      icon: RadioIcon,
    },
    {
      number: '04',
      title: 'Universal Adapters',
      description: 'REST APIs, Microservices, and more. Same framework, different adapters.',
      icon: PuzzleIcon,
    },
    {
      number: '05',
      title: 'Type-Safe',
      description: 'Leverage Dart\'s type system. Catch errors at compile time, not runtime.',
      icon: ShieldIcon,
    },
    {
      number: '06',
      title: 'OpenAPI Native',
      description: 'Unique in Dart. Generate complete API docs with just one import.',
      icon: CodeFile,
    },
  ];
</script>

<template>
	<section class="py-32 relative grain">
      <div class="absolute top-20 left-10 text-[150px] font-display font-bold text-stroke opacity-5 select-none hidden lg:block">
        02
      </div>

      <div class="container mx-auto px-6">
        <div class="grid lg:grid-cols-12 gap-8 mb-20">
          <motion.div
            :variants="scrollVariants.slideLeft"
            initial="hidden"
            whileInView="visible"
            :inViewOptions="{ once: true, amount: 0.3 }"
            :transition="{ duration: 0.6 }"
            class="lg:col-span-4"
          >
            <span class="tag text-muted-foreground mb-4 block w-fit">Features</span>
            <div class="text-4xl md:text-5xl font-display font-bold leading-tight">
              Powerful
              <br />
              <span class="font-serif italic font-normal text-muted-foreground">by design</span>
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
              Designed to make backend development in Dart easy and enjoyable.
              Avoid unnecessary complexity. Focus on your application.
            </p>
          </motion.div>
        </div>

        <!-- Features Grid - Offset layout -->
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-px bg-border">
        	<motion.div
        	  :key="feature.title"
        	  :variants="scrollVariants.scaleIn"
        	  initial="hidden"
        	  whileInView="visible"
        	  :inViewOptions="{ once: true, amount: 0.2 }"
        	  :transition="{ duration: 0.5, delay: index * 0.1 }"
        	  class="group bg-background p-8 hover:bg-card transition-colors relative"
			      v-for="(feature, index) in features"
        	>
            <!-- Number -->
        	  <span class="absolute top-4 right-4 font-mono text-xs text-muted-foreground/50">
        	    {{feature.number}}
        	  </span>
		  
        	  <motion.div 
        	    class="w-12 h-12 border-2 border-primary/30 flex items-center justify-center mb-6 group-hover:border-primary group-hover:bg-primary/10 transition-all"
        	    :whileHover="{ rotate: 5, scale: 1.05 }"
        	  >
         	    <component :is="feature.icon" class="w-5 h-5 text-primary" />
        	  </motion.div>
		  
        	  <div class="text-xl font-display font-semibold text-foreground mb-3">
        	    {{feature.title}}	
        	  </div>
        	  <p class="text-sm text-muted-foreground leading-relaxed">
        	    {{feature.description}}
        	  </p>
        	</motion.div>
        </div>
      </div>
    </section>
</template>

<style scoped>
p {
	margin: 0 !important;
}
.results{
	line-height: 1rem;
}
ol {
	padding: 0;
}
</style>