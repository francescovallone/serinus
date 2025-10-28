<script setup lang="ts">
import {
    computed,
    watch,
} from 'vue'
import { useRouter, useData } from 'vitepress'
const router = useRouter()
import DefaultTheme from 'vitepress/theme-without-fonts'


if (typeof window !== 'undefined') {
  watch(() => router.route.data.frontmatter, (frontmatter) => {
      console.log(frontmatter?.['layout'])
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
        <template #doc-before>
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
        <template #doc-footer-before>
            <div class="flex flex-col mb-8 gap-4 border-t pt-4">
                <h1 class="2xl:text-2xl text-lg font-semibold">Support Us</h1>
                <p>Serinus is MIT licensed open-source project and it grows thanks to the community's support. If you want to support us and the project, read more <a href="/support" class="text-serinus hover:text-serinus-2 underline">here</a>.</p>
                <div class="flex w-auto">
                    <a href="https://github.com/sponsors/francescovallone" class="px-8 py-4 hover:shadow-md transition-shadow font-semibold border text-center lg:text-start w-auto border-gray-300 rounded-md">Become a sponsor</a>
                </div>
            </div>
        </template>
        <template #layout-bottom>
            <div class="flex w-full gap-8 items-center 2xl:px-64 lg:px-16 px-8 flex-col border-t py-8">
                <div class="flex flex-col md:flex-row justify-between w-full" v-if="router.route.data.frontmatter['layout'] == 'page'">
                    <div class="flex gap-2">
                        <a href="https://github.com/francescovallone/serinus" target="_blank" class="p-4 hover:shadow-md transition-shadow font-semibold border text-center lg:text-start w-auto border-gray-300 rounded-md">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19c-4.3 1.4-4.3-2.5-6-3m12 5v-3.5c0-1 .1-1.4-.5-2c2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2a4.2 4.2 0 0 0-.1-3.2s-1.1-.3-3.5 1.3a12.3 12.3 0 0 0-6.2 0C6.5 2.8 5.4 3.1 5.4 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4 9.5c0 4.6 2.7 5.7 5.5 6c-.6.6-.6 1.2-.5 2V21"/></svg>
                        </a>
                        <a href="https://x.com/avesboxx" target="_blank" class="p-4 hover:shadow-md transition-shadow font-semibold border text-center lg:text-start w-auto border-gray-300 rounded-md">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="m17.687 3.063l-4.996 5.711l-4.32-5.711H2.112l7.477 9.776l-7.086 8.099h3.034l5.469-6.25l4.78 6.25h6.102l-7.794-10.304l6.625-7.571zm-1.064 16.06L5.654 4.782h1.803l10.846 14.34z"/></svg>
                        </a>
                        <a href="https://discord.gg/zydgnJ3ksJ" target="_blank" class="p-4 hover:shadow-md transition-shadow font-semibold border text-center lg:text-start w-auto border-gray-300 rounded-md">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M19.27 5.33C17.94 4.71 16.5 4.26 15 4a.1.1 0 0 0-.07.03c-.18.33-.39.76-.53 1.09a16.1 16.1 0 0 0-4.8 0c-.14-.34-.35-.76-.54-1.09c-.01-.02-.04-.03-.07-.03c-1.5.26-2.93.71-4.27 1.33c-.01 0-.02.01-.03.02c-2.72 4.07-3.47 8.03-3.1 11.95c0 .02.01.04.03.05c1.8 1.32 3.53 2.12 5.24 2.65c.03.01.06 0 .07-.02c.4-.55.76-1.13 1.07-1.74c.02-.04 0-.08-.04-.09c-.57-.22-1.11-.48-1.64-.78c-.04-.02-.04-.08-.01-.11c.11-.08.22-.17.33-.25c.02-.02.05-.02.07-.01c3.44 1.57 7.15 1.57 10.55 0c.02-.01.05-.01.07.01c.11.09.22.17.33.26c.04.03.04.09-.01.11c-.52.31-1.07.56-1.64.78c-.04.01-.05.06-.04.09c.32.61.68 1.19 1.07 1.74c.03.01.06.02.09.01c1.72-.53 3.45-1.33 5.25-2.65c.02-.01.03-.03.03-.05c.44-4.53-.73-8.46-3.1-11.95c-.01-.01-.02-.02-.04-.02M8.52 14.91c-1.03 0-1.89-.95-1.89-2.12s.84-2.12 1.89-2.12c1.06 0 1.9.96 1.89 2.12c0 1.17-.84 2.12-1.89 2.12m6.97 0c-1.03 0-1.89-.95-1.89-2.12s.84-2.12 1.89-2.12c1.06 0 1.9.96 1.89 2.12c0 1.17-.83 2.12-1.89 2.12"/></svg>
                        </a>
                    </div>
                    <div class="md:flex gap-2 hidden">
                        <a href="/blog" target="_blank" class="p-4 hover:shadow-md transition-shadow font-semibold border text-center lg:text-start w-auto border-gray-300 rounded-md">
                            Blog
                        </a>
                        <a href="/introduction.html" target="_blank" class="p-4 hover:shadow-md transition-shadow font-semibold border text-center lg:text-start w-auto border-gray-300 rounded-md">
                            Documentation
                        </a>
                        <a href="https://github.com/sponsors/francescovallone" target="_blank" class="p-4 hover:shadow-md transition-shadow font-semibold border text-center lg:text-start border-gray-300 rounded-md">
                            Become a sponsor
                        </a>
                    </div>
                </div>
                <p class="text-sm" v-if="router.route.data.frontmatter['layout'] != 'page'">
                    © 2025 Francesco Vallone. Built with 💙 and <a href="https://dart.dev" class="text-serinus hover:text-serinus-2 underline" target="_blank">Dart</a> 🎯 | One of the 🐤 of <a href="https://avesbox.com" class="text-serinus hover:text-serinus-2 underline" target="_blank">Acanthis</a>.
                </p>
                <div class="flex flex-col md:flex-row justify-between w-full" v-if="router.route.data.frontmatter['layout'] == 'page'">
                    <p class="font-medium">
                        One of the 🐤 of <a href="https://avesbox.com" class="text-serinus hover:text-serinus-2 underline" target="_blank">Acanthis</a>
                    </p>
                    <p>
                        © 2025 Francesco Vallone. All rights reserved.
                    </p>
                </div>
            </div>
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

</style>
