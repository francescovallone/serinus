<script setup>
defineProps({
  title: String,
  description: String
})
</script>

<template>
    <div class="p-4 flex justify-center items-center border border-gray-200 rounded-lg">
        <div class="flex flex-col gap-4">
            <div class="flex gap-4 items-center">
                <slot name="icon" />
                <div class="text-lg text-pretty tracking-wide text-center font-medium text-serinus">
                    {{ title }}
                </div>
            </div>
            <div class="text-sm text-pretty">
                {{ description }}
            </div>
        </div>
    </div>
</template>
