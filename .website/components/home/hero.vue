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
        <div class="container mx-auto px-6 relative z-10">
            <div class="grid lg:grid-cols-12 gap-8 items-start pt-20">
                <div class="lg:col-span-7">
                    <motion.div 
                        class="tag text-primary mb-8" 
                        :initial="{ opacity: 0 }"
                        :animate="{ opacity: 1 }"
                        :transition="{ duration: 0.6, delay: 0.1 }"
                    >
                        v2.0 - Dawn Chorus
                    </motion.div>
                    
                    <motion.div
                        class="mb-8"
                        :initial="{ opacity: 0 }"
                        :animate="{ opacity: 1 }"
                        :transition="{ duration: 0.6, delay: 0.1 }"
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
                    >
                        The first Dart backend framework designed to work seamlessly with Flutter and Dart applications.
                        Skip the learning curve & build server-side apps with the language you already know.
                    </motion.div>
                    <motion.div 
                        class="flex flex-wrap gap-4 mb-12"
                        :initial="{ opacity: 0, y: 20 }"
                        :animate="{ opacity: 1, y: 0 }"
                        :transition="{ duration: 0.5, delay: 0.4 }"
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

                    <cli-sequence />
                </div>
                <motion.div
                    :initial="{ opacity: 0, y: 40 }"
                    :animate="{ opacity: 1, y: 0 }"
                    :transition="{ duration: 0.7, delay: 0.3 }"
                    class="lg:col-span-5 relative"
                >
                    <motion.div
                        class="absolute -top-16 -left-8 z-20"
                        :animate="{ y: [0, -15, 0], rotate: [0, 5, 0] }"
                        :transition="{ duration: 5, repeat: Infinity, ease: 'easeInOut' }"
                    >
                        <img
                            src='/serinus-logo.png'
                            alt="Serinus Mascot"
                            class="w-28 h-28 drop-shadow-2xl"
                        />
                    </motion.div>
                    
                    <div class="lg:mt-16">
                    </div>
                    
                    <div className="absolute -bottom-4 -right-4 bg-primary text-primary-foreground px-4 py-2 font-mono text-xs uppercase tracking-wider">
                        6 lines to launch
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
.tag {
	font-family: 'Space Mono', 'JetBrains Mono', monospace;
	display: inline-block;
	border-width: 1px;
	border-color: currentColor;
	padding-left: 0.75rem;
	padding-right: 0.75rem;
	padding-top: 0.25rem;
	padding-bottom: 0.25rem;
	font-family: Space Mono, JetBrains Mono, monospace;
	font-size: 0.75rem;
	line-height: 1rem;
	text-transform: uppercase;
	letter-spacing: 0.1em;
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