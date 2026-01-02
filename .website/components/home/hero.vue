<script setup>
import { motion } from 'motion-v';
import CliSequence from './cli_sequence.vue';

</script>

<template>
	<section class="relative min-h-screen pt-24 overflow-hidden grain">
        <div class="absolute top-20 right-10 text-[200px] font-display leading-none font-bold text-stroke opacity-10 select-none hidden lg:block">
            01
        </div>
        <motion.div
            class="absolute top-40 right-[20%] w-20 h-20 border-2 border-primary/30 rounded-full"
        />
        <div
            class="absolute bottom-40 left-[10%] w-32 h-32 border border-muted-foreground/20"
            style="transform: rotate(45deg);"
        />
        <motion.div
            class="absolute top-4 right-4 z-20 block md:hidden"
            :animate="{ y: [0, -15, 0], rotate: [0, 5, 0] }"
            :transition="{ duration: 5, repeat: Infinity, ease: 'easeInOut' }"
            :viewport="{ once: true }"
        >
            <img
                src='/serinus-logo.png'
                alt="Serinus Mascot"
                class="w-28 h-28 drop-shadow-2xl"
            />
        </motion.div>
        <div class="container mx-auto px-6 relative z-10">
            <div class="grid lg:grid-cols-12 gap-8 items-start pt-20">
                <div class="lg:col-span-7">
                    <motion.div 
                        class="tag text-primary mb-8" 
                        :initial="{ opacity: 0 }"
                        :animate="{ opacity: 1 }"
                        :transition="{ duration: 0.6, delay: 0.1 }"
                        :viewport="{ once: true }"
                    >
                        v2.0 - Dawn Chorus
                    </motion.div>
                    
                    <motion.div
                        class="mb-8"
                        :initial="{ opacity: 0 }"
                        :animate="{ opacity: 1 }"
                        :transition="{ duration: 0.6, delay: 0.1 }"
                        :viewport="{ once: true }"
                    >
                        <div class="text-5xl md:text-7xl lg:text-8xl font-display font-bold leading-[0.9] tracking-tight mb-4">
                            <span class="text-primary">Backend</span>
                            <br />
                            <span class="text-foreground">for Dart.</span>
                        </div>
                        <div class="text-2xl md:text-3xl font-serif italic text-muted-foreground mt-6">
                            Opinionated to just the right degree.
                        </div>
                    </motion.div>
                    <motion.div 
                        class="text-lg text-muted-foreground max-w-xl mb-10 leading-relaxed"
                        :initial="{ opacity: 0, y: 20 }"
                        :animate="{ opacity: 1, y: 0 }"
                        :transition="{ duration: 0.5, delay: 0.3 }"
                        :viewport="{ once: true }"
                    >
                        The opinionated Dart backend framework designed to work seamlessly with Flutter and Dart applications.
                        Skip the learning curve & build server-side apps with the language you already know.
                    </motion.div>
                    <motion.div 
                        class="flex md:flex-row flex-col flex-wrap gap-4 mb-12"
                        :initial="{ opacity: 0, y: 20 }"
                        :animate="{ opacity: 1, y: 0 }"
                        :transition="{ duration: 0.5, delay: 0.4 }"
                        :viewport="{ once: true }"
                    >
                        <a
                            href="https://serinus.app/introduction.html"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="group inline-flex items-center gap-3 px-6 py-4 bg-primary !text-primary-foreground font-display font-semibold text-lg hover:gap-5 transition-all"
                        >
                            Get Started
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14m-6 6l6-6m-6-6l6 6"/></svg>
                        </a>
                        <a
                            href="https://discord.gg/zydgnJ3ksJ"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="inline-flex items-center gap-3 px-6 py-4 editorial-border text-foreground font-display font-semibold text-lg hover:bg-foreground transition-all"
                        >
                            Join Community
                        </a>
                        
                    </motion.div>

                    <cli-sequence class="hidden md:block" />
                </div>
                <motion.div
                    :initial="{ opacity: 0, y: 40 }"
                    :animate="{ opacity: 1, y: 0 }"
                    :transition="{ duration: 0.7, delay: 0.3 }"
                    :viewport="{ once: true }"
                    class="lg:col-span-5 relative"
                >
                    <motion.div
                        class="absolute -top-16 -left-8 z-20 md:block hidden"
                        :animate="{ y: [0, -15, 0], rotate: [0, 5, 0] }"
                        :transition="{ duration: 5, repeat: Infinity, ease: 'easeInOut' }"
                        :viewport="{ once: true }"
                    >
                        <img
                            src='/serinus-logo.png'
                            alt="Serinus Mascot"
                            class="w-28 h-28 drop-shadow-2xl"
                        />
                    </motion.div>
                    
                    <div class="lg:mt-16 starting-hero md:block hidden">
                        <slot />
                    </div>
                    
                    <div class="md:block hidden absolute -bottom-4 -right-4 bg-primary text-primary-foreground px-4 py-2 font-mono text-xs uppercase tracking-wider">
                        Modular by Design
                    </div>
                </motion.div>
            </div>
        </div>
  	</section>
</template>

<style scoped>
#learn-more {
    color: rgba(255, 255, 255, 0.7);
}
.results{
	line-height: 1rem;
}
ol {
	padding: 0;
}
a:hover {
	color: hsl(var(--background)) !important;
}
</style>

<style>

@reference 'tailwindcss';

.starting-hero > .vp-code-group div[class*="language-"] .lang {
    display: none;
}
.starting-hero > .vp-code-group div[class*="language-"] > .copy {
    display: none;
}
</style>