<script setup>
defineProps({
  width: { type: [Number, String], default: 688 },
  height: { type: [Number, String], default: 400 }
})
</script>

<template>
  <svg :width="width" :height="height" xmlns="http://www.w3.org/2000/svg">
    <slot />
  </svg>
</template>
