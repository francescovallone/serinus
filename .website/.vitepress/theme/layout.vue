<script setup lang="ts">
import {
    computed,
    watch,
} from 'vue'
import { useRouter } from 'vitepress'
const { route } = useRouter()
import DefaultTheme from 'vitepress/theme-without-fonts'
import { DiscordIcon, GithubIcon, MessageIcon, XSocialIcon } from '../../components/home/icons';
import OpenIn from '../../components/open-in.vue';

</script>

<template>
    <DefaultTheme.Layout>
        <template #doc-footer-before>
            <div class="flex flex-col mb-8 gap-4 border-t border-border-imp pt-4">
                <div class="2xl:text-2xl text-lg font-semibold">Support Us</div>
                <p>Serinus is MIT licensed open-source project and it grows thanks to the community's support. If you want to support us and the project, read more <a href="/support" class="text-serinus hover:text-serinus-2 underline">here</a>.</p>
                <div class="flex w-auto">
                    <a
                        href="https://discord.gg/zydgnJ3ksJ"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="sponsor-link inline-flex items-center gap-3 px-6 py-4 editorial-border text-foreground font-display font-semibold text-lg hover:bg-foreground transition-all"
                    >
                        Become a sponsor
                    </a>
                </div>
            </div>
            <OpenIn />
        </template>
        <template #layout-bottom>
            <div class="flex w-full gap-8 items-center 2xl:px-64 lg:px-16 px-8 flex-col py-8 z-40" v-if="route.data.frontmatter['layout'] !== 'page' && route.data.frontmatter['sidebar'] !== false">
                <p class="text-sm">
                    © 2025 Francesco Vallone. Built with 💙 and <a href="https://dart.dev" class="text-serinus hover:text-serinus-2 underline" target="_blank">Dart</a> 🎯 | One of the 🐤 of <a href="https://avesbox.com" class="text-serinus hover:text-serinus-2 underline" target="_blank">Avesbox</a>.
                </p>
            </div>
            <footer v-if="route.data.frontmatter['layout'] === 'page' || route.data.frontmatter['sidebar'] === false" class="border-t-2 border-border bg-card z-10">
                <div class="container mx-auto px-6 py-16">
                    <div class="grid grid-cols-1 md:grid-cols-12 gap-12">
                        <div class="md:col-span-4">
                            <a href="/" class="flex items-center gap-3 mb-6">
                                <img src="/serinus-logo.png" alt="Serinus" class="w-10 h-10" />
                                <span class="text-xl font-display font-bold text-foreground">Serinus</span>
                            </a>
                            <p class="text-muted-foreground mb-6! leading-relaxed">
                                The first Dart backend framework, opinionated to just the right degree.
                            </p>
                            <div class="flex items-center gap-2">
                                <a
                                    href="https://github.com/francescovallone/serinus"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="p-2 border border-border! text-muted-foreground! hover:text-foreground! hover:border-foreground! transition-all"
                                >
                                    <GithubIcon class="w-5 h-5" />
                                </a>
                                <a
                                    href="https://discord.gg/zydgnJ3ksJ"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="p-2 border border-border! text-muted-foreground! hover:text-foreground! hover:border-foreground! transition-all"
                                >
                                    <DiscordIcon class="w-5 h-5" />
                                </a>
                                <a
                                    href="https://twitter.com/francescovallo1"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="p-2 border border-border! text-muted-foreground! hover:text-foreground! hover:border-foreground! transition-all"
                                >
                                    <XSocialIcon />
                                </a>
                            </div>
                        </div>

                        <div class="md:col-span-2 md:col-start-6">
                            <div class="font-display font-semibold text-foreground mb-4 uppercase tracking-wider text-sm">Resources</div>
                            <ul class="space-y-3">
                                <li>
                                    <a
                                        href="https://serinus.app/introduction.html"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="text-muted-foreground! hover:text-primary! transition-colors hover-underline"
                                    >
                                        Docs
                                    </a>
                                </li>
                            <li>
                                <a href="/blog" class="text-muted-foreground! hover:text-primary! transition-colors hover-underline">
                                    Blog
                                </a>
                            </li>
                            <li>
                                <a
                                    href="https://pub.dev/packages/serinus"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="text-muted-foreground! hover:text-primary! transition-colors hover-underline"
                                >
                                    pub.dev
                                </a>
                            </li>
                            </ul>
                        </div>

                        <div class="md:col-span-2">
                            <div class="font-display font-semibold text-foreground mb-4 uppercase tracking-wider text-sm">Community</div>
                            <ul class="space-y-3">
                                <li>
                                    <a
                                        href="https://discord.gg/zydgnJ3ksJ"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="text-muted-foreground! hover:text-primary! transition-colors hover-underline"
                                    >
                                        Discord
                                    </a>
                                </li>
                                <li>
                                    <a
                                        href="https://github.com/francescovallone/serinus"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="text-muted-foreground! hover:text-primary! transition-colors hover-underline"
                                    >
                                        GitHub
                                    </a>
                                </li>
                                <li>
                                    <a
                                        href="https://github.com/sponsors/francescovallone"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="text-muted-foreground! hover:text-primary! transition-colors hover-underline"
                                    >
                                        Sponsor
                                    </a>
                                </li>
                            </ul>
                        </div>

                        <div class="md:col-span-2">
                            <div class="font-display font-semibold text-foreground mb-4 uppercase tracking-wider text-sm">About</div>
                            <ul class="space-y-3">
                                <li>
                                    <a
                                        href="https://avesbox.com/"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="text-muted-foreground! hover:text-primary! transition-colors hover-underline"
                                    >
                                        Avesbox
                                    </a>
                                </li>
                                <li>
                                    <a
                                        href="https://github.com/francescovallone"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="text-muted-foreground! hover:text-primary! transition-colors hover-underline"
                                    >
                                    Creator
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>
                    <div class="mt-16 pt-8 border-t border-border flex flex-col md:flex-row justify-between items-center gap-4">
                        <p class="text-sm text-muted-foreground font-mono">
                            © 2025 Francesco Vallone
                        </p>
                        <p class="text-sm text-muted-foreground">
                            One of the 🐤 of
                            <a
                                href="https://avesbox.com/"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="text-primary! hover-underline"
                            >
                                Avesbox
                            </a>
                        </p>
                    </div>
                </div>
            </footer>
            
        </template>
    </DefaultTheme.Layout>
</template>

<style>
.doc-before-interaction {
	transition: color 0.2s ease-in-out;
}
.doc-before-interaction:hover {
	color: var(--vp-c-brand-1);
}
a.sponsor-link:hover {
	color: hsl(var(--background)) !important;
}
</style>
