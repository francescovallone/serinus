<script setup>
</script>

<template>
	<div class="container flex w-full h-dvh gap-8 flex-col items-center justify-center">
        <div class="relative w-72 h-72">
            <div class="bg-gradient-to-r from-yellow-400 to-orange-500 rounded-full absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-96 h-96 blur-3xl z-[-1]"></div>
            <img src="/serinus-logo.png" alt="Serinus Logo" class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-72 h-72" />
        </div>
        <div class="flex flex-col items-center">
            <div class="text-6xl lg:text-8xl font-bold">Serinus</div>
            <div class="my-4 lg:my-8 text-xl lg:text-2xl text-gray-300 text-center">
                A backend framework for building efficient and scalable server-side applications <br /><span class="font-semibold">Powered by Dart 🎯</span>
            </div>
            <div class="flex flex-col lg:flex-row justify-center items-center gap-4">
                <a href="/introduction.html" class="bg-orange-400 px-8 py-4 rounded-full">Get Started</a>
                <a href="https://discord.gg/zydgnJ3ksJ" class="px-8 py-4">Join the community</a>
            </div>
        </div>
        <a href="#fast" id="learn-more" class="text-sm">Learn more</a>
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