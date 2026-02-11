<script setup>
defineProps({
  x: { type: [Number, String], required: true },
  y: { type: [Number, String], required: true },
  variant: { type: String, default: 'default' }, // 'default', 'brand', 'muted'
  customStyle: { type: [Object, String], default: () => ({}) }
})
</script>

<template>
  <text :x="x" :y="y" :class="['text', `text-${variant}`]" :style="customStyle">
    <slot />
  </text>
</template>

<style scoped>
.text {
  font-size: 14px;
  text-anchor: middle;
  font-weight: 600;
  fill: var(--primary-foreground);
}
.text-brand {
  fill: var(--vp-c-brand-1);
}
.text-muted {
  fill: #aaa;
  font-size: 12px;
}
</style>
