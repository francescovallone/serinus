<script setup>
defineProps({
  x: { type: [Number, String], required: true },
  y: { type: [Number, String], required: true },
  width: { type: [Number, String], default: 150 },
  height: { type: [Number, String], default: 60 },
  variant: { type: String, default: 'filled' }, // 'filled', 'stroke'
  rx: { type: [Number, String], default: 0 },
  customStyle: { type: [Object, String], default: () => ({}) },
  label: String,
  labelVariant: { type: String, default: 'default' } // 'default', 'brand', 'muted'
})
</script>

<template>
  <g>
    <rect
      :x="x"
      :y="y"
      :width="width"
      :height="height"
      :rx="rx"
      :class="['box', variant === 'stroke' ? 'stroke' : '']"
      :style="customStyle"
    />
    <text
      v-if="label"
      :x="Number(x) + Number(width) / 2"
      :y="Number(y) + Number(height) / 2 + 5"
      :class="['text', `text-${labelVariant}`]"
    >
      {{ label }}
    </text>
  </g>
</template>

<style scoped>
.box {
  font-size: 16px;
  font-family: sans-serif;
  fill: var(--vp-c-brand-1);
  stroke: none;
  fill-opacity: 1;
}
.box.stroke {
  stroke: var(--vp-c-brand-1);
  stroke-width: 2;
  fill: transparent;
}
.text {
  font-size: 14px;
  text-anchor: middle;
  font-weight: 600;
  pointer-events: none;
}
.text-default {
  fill: white; /* default for most */
}
.text-brand {
  fill: var(--vp-c-brand-1);
}
.text-muted {
  fill: #aaa;
  font-size: 12px;
}
</style>
