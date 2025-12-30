<script setup lang="ts">
import {
    computed,
    watch,
} from 'vue'
import { useRouter, useData } from 'vitepress'
const router = useRouter()
import DefaultTheme from 'vitepress/theme-without-fonts'
import { GithubIcon, MessageIcon, XSocialIcon } from '../../components/home/icons';


if (typeof window !== 'undefined') {
  watch(() => router.route.data.frontmatter, (frontmatter) => {
      console.log(frontmatter?.['layout'])
      console.log(frontmatter)
  }, { immediate: true });
}

const prompt = computed(() =>
    encodeURI(
        `I'm looking at https://serinus.app${router.route.path}.\n\nWould you kindly explain, summarize the concept, and answer any questions I have about it?`
    )
)
</script>

<template>
    <DefaultTheme.Layout>
        <template #doc-footer-before>
            <div class="flex flex-col mb-8 gap-4 border-t border-border pt-4">
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
            <div
                id="open-serinus-in"
                class="flex gap-2 sm:justify-end items-center font-mono pt-1 pr-0 text-gray-400 text-xs *:z-20 [&>a>svg]:size-4 sm:[&>a>svg]:size-5"
            >
                Open in
                <a
                    :href="`https://chatgpt.com/?prompt=${prompt}`"
                    class="doc-before-interaction"
                    target="_blank"
                    rel="noopener noreferrer"
                    title="Open in ChatGPT"
                >
                    <svg
                        preserveAspectRatio="xMidYMid"
                        viewBox="0 0 256 260"
                        fill="currentColor"
                    >
                        <path
                            d="M239.184 106.203a64.716 64.716 0 0 0-5.576-53.103C219.452 28.459 191 15.784 163.213 21.74A65.586 65.586 0 0 0 52.096 45.22a64.716 64.716 0 0 0-43.23 31.36c-14.31 24.602-11.061 55.634 8.033 76.74a64.665 64.665 0 0 0 5.525 53.102c14.174 24.65 42.644 37.324 70.446 31.36a64.72 64.72 0 0 0 48.754 21.744c28.481.025 53.714-18.361 62.414-45.481a64.767 64.767 0 0 0 43.229-31.36c14.137-24.558 10.875-55.423-8.083-76.483Zm-97.56 136.338a48.397 48.397 0 0 1-31.105-11.255l1.535-.87 51.67-29.825a8.595 8.595 0 0 0 4.247-7.367v-72.85l21.845 12.636c.218.111.37.32.409.563v60.367c-.056 26.818-21.783 48.545-48.601 48.601Zm-104.466-44.61a48.345 48.345 0 0 1-5.781-32.589l1.534.921 51.722 29.826a8.339 8.339 0 0 0 8.441 0l63.181-36.425v25.221a.87.87 0 0 1-.358.665l-52.335 30.184c-23.257 13.398-52.97 5.431-66.404-17.803ZM23.549 85.38a48.499 48.499 0 0 1 25.58-21.333v61.39a8.288 8.288 0 0 0 4.195 7.316l62.874 36.272-21.845 12.636a.819.819 0 0 1-.767 0L41.353 151.53c-23.211-13.454-31.171-43.144-17.804-66.405v.256Zm179.466 41.695-63.08-36.63L161.73 77.86a.819.819 0 0 1 .768 0l52.233 30.184a48.6 48.6 0 0 1-7.316 87.635v-61.391a8.544 8.544 0 0 0-4.4-7.213Zm21.742-32.69-1.535-.922-51.619-30.081a8.39 8.39 0 0 0-8.492 0L99.98 99.808V74.587a.716.716 0 0 1 .307-.665l52.233-30.133a48.652 48.652 0 0 1 72.236 50.391v.205ZM88.061 139.097l-21.845-12.585a.87.87 0 0 1-.41-.614V65.685a48.652 48.652 0 0 1 79.757-37.346l-1.535.87-51.67 29.825a8.595 8.595 0 0 0-4.246 7.367l-.051 72.697Zm11.868-25.58 28.138-16.217 28.188 16.218v32.434l-28.086 16.218-28.188-16.218-.052-32.434Z"
                        />
                    </svg>
                </a>

                <a
                    :href="`https://claude.ai/new?q=${prompt}`"
                    class="doc-before-interaction"
                    target="_blank"
                    rel="noopener noreferrer"
                    title="Open in Claude"
                >
                    <svg
                        fill-rule="evenodd"
                        viewBox="0 0 24 24"
                        fill="currentColor"
                    >
                        <title>Anthropic</title>
                        <path
                            d="M13.827 3.52h3.603L24 20h-3.603l-6.57-16.48zm-7.258 0h3.767L16.906 20h-3.674l-1.343-3.461H5.017l-1.344 3.46H0L6.57 3.522zm4.132 9.959L8.453 7.687 6.205 13.48H10.7z"
                        />
                    </svg>
                </a>

                <a
                    :href="`https://serinus.app${router.route.path.replace(/.html$/g, '')}.md`"
                    class="doc-before-interaction"
                    target="_blank"
                    rel="noopener noreferrer"
                    title="Open in Markdown"
                >
                    <svg
						xmlns="http://www.w3.org/2000/svg"
						viewBox="0 0 24 24"
						fill="currentColor"
					>
						<title>Markdown</title>
						<path
							d="M4.5 3A2.5 2.5 0 0 0 2 5.5v13A2.5 2.5 0 0 0 4.5 21h15a2.5 2.5 0 0 0 2.5-2.5v-13A2.5 2.5 0 0 0 19.5 3h-15zm0 1.5h15A1 1 0 0 1 20.5 5.5v13a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1v-13A1 1 0 0 1 4.5 4.5zm1.75 3.25v8.5h1.5v-3.25l2.25 3.25h1.75v-8.5h-1.5v3.25l-2.25-3.25h-1.75zm8.75-.25h4v1.5h-4v-1.5zm0 3h4v1.5h-4v-1.5zm0 3h4v1.5h-4v-1.5z"
						/>
					</svg>
                </a>
            </div>
        </template>
        <template #layout-bottom>
            <div class="flex w-full gap-8 items-center 2xl:px-64 lg:px-16 px-8 flex-col py-8 z-40" v-if="router.route.data.frontmatter['layout'] !== 'page' && router.route.data.frontmatter['sidebar'] !== false">
                <p class="text-sm">
                    © 2025 Francesco Vallone. Built with 💙 and <a href="https://dart.dev" class="text-serinus hover:text-serinus-2 underline" target="_blank">Dart</a> 🎯 | One of the 🐤 of <a href="https://avesbox.com" class="text-serinus hover:text-serinus-2 underline" target="_blank">Avesbox</a>.
                </p>
            </div>
            <footer v-if="router.route.data.frontmatter['layout'] === 'page' || router.route.data.frontmatter['sidebar'] === false" class="border-t-2 border-border bg-card/30">
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
                                    <MessageIcon class="w-5 h-5" />
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
