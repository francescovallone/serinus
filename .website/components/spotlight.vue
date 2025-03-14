<script setup lang="ts">
import { defineProps, onMounted } from 'vue'
import { Spotlight } from './data/spotlights.ts'

const props = defineProps<{
    spotlights: Spotlight[]
}>()

const isOdd = props.spotlights.length % 2 !== 0
console.log(isOdd)
</script>

<template>
    <div id="spotlights" class="flex items-center justify-center">
        <div  class="container grid grid-cols-6 gap-16">
            <div 
                v-for="(item, index) in props.spotlights" 
                :id="'spot-' + index" 
                :key="item.title" 
                class="flex col-span-6 gap-4 rounded-xl p-14 justify-between relative overflow-hidden" 
                :class="[
                    isOdd && index === props.spotlights.length - 1 ? [
                        'flex-row',
                        '',
                        'h-96',
                        'min-h-96'
                    ] : [
                        'flex-col',
                        'md:col-span-3',
                        'min-h-192'
                    ]
                ]" 
                :style='{
                    backgroundColor: `${item.color}`,
                    color: `${item.textColor}`
                }'
            >
                <div class="flex flex-col gap-4" :class="isOdd && index === props.spotlights.length - 1 ? 'justify-center' : ''">
                    <h1 class="text-3xl font-semibold">{{ item.title }}</h1>
                    <p class="text-lg">{{ item.subtitle }}</p>
                    <a 
                        :href="item.href" 
                        class="cta bg-white w-fit px-6 py-4 rounded-full font-medium hover:bg-transparent transition-all border-2 border-white"
                        :style='{
                            color: `${item.color}`
                        }'
                    >
                        {{ item.cta }}
                    </a>
                </div>
                <img 
                    v-if="item.src"
                    :src="item.src" 
                    :alt="item.alt" 
                    class="rounded-lg" 
                    :class="isOdd && index === props.spotlights.length - 1 ? 'w-1/2' : 'w-full'"
                />
                <img src="/feather.png" alt="feather" class="absolute right-16 w-16" :class="isOdd && index === props.spotlights.length - 1 ? 'top-16' : 'bottom-16'" />
            </div>
        </div>
    </div>
</template>

<style lang="css" scoped>

    .cta:hover {
        color: white !important;
    }
</style>