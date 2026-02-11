<script setup>
defineProps({
  d: { type: String, default: '' },
  x1: [Number, String],
  y1: [Number, String],
  x2: [Number, String],
  y2: [Number, String],
  animated: { type: Boolean, default: false },
  dashed: { type: Boolean, default: false }
})
</script>

<template>
  <g>
    <!-- Dashed Line Style (uses <line> or <path>) -->
    <template v-if="dashed">
      <path 
        v-if="d" 
        :d="d" 
        class="arrow arrow-dashed"
      >
         <animate
            attributeName="stroke-dashoffset"
            values="100;0"
            dur="3s"
            calcMode="linear"
            repeatCount="indefinite" 
         />
      </path>
      <line 
        v-else 
        :x1="x1" :y1="y1" :x2="x2" :y2="y2" 
        class="arrow arrow-dashed"
      >
          <animate
            attributeName="stroke-dashoffset"
            values="100;0"
            dur="3s"
            calcMode="linear"
            repeatCount="indefinite" 
          />
      </line>
    </template>

    <!-- Flow Animation Style (Double path) -->
    <template v-else-if="animated">
       <path :d="d" class="arrow top-arrow" />
       <path :d="d" class="arrow mid-arrow" />
    </template>
    
    <!-- Simple Static Arrow -->
    <template v-else>
       <path v-if="d" :d="d" class="arrow" />
       <line v-else :x1="x1" :y1="y1" :x2="x2" :y2="y2" class="arrow" />
    </template>
  </g>
</template>

<style scoped>
.arrow {
  stroke: #d5d5d5;
  fill: none;
  stroke-width: 2;
}
.arrow-dashed {
  stroke-dasharray: 10;
  stroke-dashoffset: 5;
  stroke: var(--vp-c-brand-1);
}
.top-arrow {
  stroke-linejoin: round;
}
.mid-arrow {
  stroke-dasharray: 10, 40;
  stroke-dashoffset: 200;
  stroke-linejoin: bevel;
  animation: dash 3s linear forwards;
  animation-iteration-count: infinite;
  stroke: var(--vp-c-brand-1);
}
@keyframes dash {
  to {
    stroke-dashoffset: 0;
  }
}
</style>
