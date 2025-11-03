<script setup>
import { onMounted, ref } from 'vue'

const copiedCliCommand = ref(false);
const copiedCreateProjectCommand = ref(false);
function copyCliCommand() {
    navigator.clipboard.writeText('dart pub global activate serinus_cli');
    copiedCliCommand.value = true;
}
function copyCreateProjectCommand() {
    navigator.clipboard.writeText('serinus create example_app');
    copiedCreateProjectCommand.value = true;
}

onMounted(() => {
    const words = ['Flutter', 'Dart', 'Backend'];
    startTypingEffect(words, 'change-keyword', 2000);
});

function startTypingEffect(words, elementId, delay) {
    let currentWordIndex = 0;
    let currentCharIndex = 0;
    let isDeleting = false;
    const element = document.getElementById(elementId);

    function type() {
        const currentWord = words[currentWordIndex];
        if (isDeleting) {
            currentCharIndex--;
            element.innerText = currentWord.substring(0, currentCharIndex);
            if (currentCharIndex === 0) {
                isDeleting = false;
                currentWordIndex = (currentWordIndex + 1) % words.length;
                setTimeout(type, 250);
            } else {
                setTimeout(type, 100);
            }
        } else {
            currentCharIndex++;
            element.innerText = currentWord.substring(0, currentCharIndex);
            if (currentCharIndex === currentWord.length) {
                isDeleting = true;
                setTimeout(type, delay);
            } else {
                setTimeout(type, 100);
            }
        }
    }

    type();
}

</script>

<template>
	<div class="flex w-full lg:h-[calc(100vh-128px)] gap-8 items-center justify-between 2xl:px-64 lg:px-16 px-8 flex-col md:flex-row">
        <div class="flex flex-col gap-4 w-full">
            <div class="text-gray-400 text-sm font-mono tracking-widest">
                HeroModule()
            </div>
            <div class="flex flex-col items-start">
                <div class="text-4xl lg:text-6xl 2xl:w-[54rem] lg:w-[36rem] text-pretty"><span class="text-serinus font-semibold">Designed for Scale</span>,<br /> Crafted for <span id="change-keyword">Flutter</span> Developers.</div>
                <div class="my-4 lg:my-8 text-md lg:text-lg 2xl:w-[48rem] lg:w-[32rem] text-pretty text-gray-600">
                    Serinus provides a powerful and flexible framework for building server-side applications in Dart. Our open-source Dart framework, packages, and tools make it easy to create high-performance, scalable, and maintainable applications. 
                </div>
                <div class="flex flex-col lg:flex-row justify-center w-full lg:w-auto items-center gap-2 border-dashed border-2 border-gray-300 rounded-lg p-4 relative">
                    <div class="absolute -top-2 left-2 px-2 bg text-xs text-gray-400 rounded-md font-mono text-sm tracking-widest">HeroController()</div>
                    <a href="/introduction.html" class="bg-serinus hover:shadow-md transition-shadow px-8 py-4 rounded-md text-white text-center lg:text-start w-full lg:w-auto font-semibold">Get Started</a>
                    <a href="/discord.html" class="px-8 py-4 hover:shadow-md transition-shadow font-semibold border w-full text-center lg:text-start lg:w-auto border-gray-300 rounded-md">Join the community</a>
                </div>
            </div>
            <div id="cli-command-copy" @click="copyCliCommand" class="flex gap-4 items-center cursor-pointer">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="#ff8904" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 7l5 5l-5 5m7 2h7"/></svg>
                <div class="text-gray-600 font-medium font-mono text-sm lg:text-md">dart pub global activate serinus_cli</div>
                <svg v-if="copiedCliCommand" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="rgb(156,163,175)" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 12l5 5L20 7"/></svg>
            </div>
            <div v-if="copiedCliCommand" @click="copyCreateProjectCommand" id="create-project-command-copy" class="flex gap-4 items-center cursor-pointer">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="#ff8904" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 7l5 5l-5 5m7 2h7"/></svg>
                <div class="text-gray-600 font-medium font-mono text-sm lg:text-md">serinus create example_app</div>
                <svg v-if="copiedCreateProjectCommand" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="rgb(156,163,175)" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5 12l5 5L20 7"/></svg>
            </div>
            <div v-if="copiedCreateProjectCommand" class="text-sm text-gray-500">
                Congrats, you are good to go! <a class="text-orange-400 underline" href="/introduction.html">Read the documentation</a>.
            </div>
        </div>
        <div class="w-full flex-col gap-4 hidden lg:flex">
            <div class="text-gray-400 text-xs font-mono tracking-widest">
                CodeProvider()
            </div>
            <div class="w-full flex items-center justify-center starting-hero rounded-lg overflow-hidden">
                <slot></slot>
            </div>
        </div>
  	</div>
</template>

<style scoped>
#learn-more {
    color: rgba(255, 255, 255, 0.7);
}
.vp-doc a {
    color: white;
    text-decoration: none;
}
.vp-doc a.text-black {
    color: rgb(27, 27, 31);
}
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

<style>
.starting-hero > .vp-code-group div[class*="language-"] .lang {
    display: none;
}
.starting-hero > .vp-code-group div[class*="language-"] > .copy {
    display: none;
}
</style>