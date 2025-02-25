<script setup>
const props = defineProps({
    title: String,
    lang: String,
    value: Number,
    isFirst: Boolean,
    max: Number,
    label: String
})

const scale = (value, max) => (value / max) * 100
const scaleStyle = (value, max) =>
	`width: ${((value / max) * 100).toFixed(2)}%`
const scalePadding = (value, max) =>
	`padding-left: ${((value / max) * 100).toFixed(2)}%`
const format = new Intl.NumberFormat().format

</script>

<template>
    <div class="flex flex-row w-full gap-4">
        <p
            class="flex items-end gap-2 w-full max-w-[8em] dark:text-gray-400"
        >
            {{ title }}
            <span class="text-gray-400 text-xs pb-1">
                {{ lang }}
            </span>
        </p>
        <div class="w-full h-7 relative">
            <div
                :class="['flex justify-end items-center text-sm px-2.5 py-0.5 rounded-full mr-auto h-7', (isFirst ? 'text-white font-extrabold bg-gradient-to-r from-yellow-400 to-orange-500' : 'bg-gray-200 dark:bg-gray-700')]"
                :style="[scaleStyle(value, max)]"
            >
                <span
                    v-if="scale(value, max) > 40"
                    class="absolute z-1 flex items-center text-sm h-7"
                >
                    {{ format(value, max) }} {{ isFirst ? label : '' }}
                </span>
            </div>
            <span
                v-if="scale(value, max) <= 40"
                :class="['absolute top-0 flex items-center text-sm h-7 left-2', (isFirst ? 'text-white font-extrabold' : '')]"
                :style="scalePadding(value, max)"
            >
                {{ format(value, max) }} {{ isFirst ? label : '' }}
            </span>
        </div>
    </div>
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