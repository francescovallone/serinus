<script setup>
const partners = [
    {
        name: 'Orbyta',
        link: 'https://orbyta.it',
        logo: 'https://orbyta.it/wp-content/uploads/2024/11/orbyta_logo.svg'
    },
]
</script>

<template>
	<div class="container flex w-full gap-8 flex-col my-8">
		<div class="container flex w-full gap-4 flex-col">
			<h1 class="text-xl text-white">Partners</h1>
            <p class="text-gray-400">
                We are proud to be partnered with the following companies and organizations that share our vision for Serinus.
            </p>
			<section class="flex gap-4 flex-wrap">
				<a target="_blank" v-for="(partner, index) in partners" :key="partner.name" :class="[
                    'plugin flex items-center transition-all size-32 p-4 rounded-lg grayscale hover:grayscale-0',
                    index % 2 === 0 ? 'bg-neutral-900' : ''
                ]" :href="partner.link" noopener noreferrer>
					<img :src="partner.logo" :alt="partner.name" class="rounded-lg"/>
				</a>
			</section>
		</div>
  	</div>
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
.plugin {
	border: 1px solid transparent;
}
.plugin:hover {
	border: 1px solid var(--vp-c-brand-2);
}
</style>