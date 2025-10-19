<script setup>
</script>

<template>
	<svg width="690" height="400" xmlns="http://www.w3.org/2000/svg">
    	<rect x="80" y="50" width="150" height="60" class="box" rx="12" ry="12"/>
		<text x="155" y="85" class="text">Permission</text>
		<rect x="460" y="50" width="150" height="60" class="box" rx="12" ry="12"/>
		<text x="535" y="85" class="text">AuthStrategy</text>

		<path d="M155 110 C155 200, 155 200, 270 200" class="arrow top-arrow arrow-dashed"/>
		<path d="M535 110 C535 200, 535 200, 420 200" class="arrow top-arrow arrow-dashed"/>

		<rect x="270" y="170" width="150" height="60" class="box stroke" rx="12" ry="12"/>
		<text x="345" y="205" class="text-brand">Route</text>
  	</svg>
</template>

<!-- Styles -->
<style scoped>
    .box {
      font-size: 16px;
      font-family: sans-serif;
      fill: var(--vp-c-brand-light);
      stroke: none;
      fill-opacity: 1;
    }
    .box.stroke {
      stroke: var(--vp-c-brand-1);
      stroke-width: 2;
      fill: transparent
    }
    .text {
      fill: white;
      font-family: Arial, sans-serif;
      font-size: 14px;
      text-anchor: middle;
      font-weight: 600;
    }
    .text-brand {
      fill: var(--vp-c-brand-1);
	    font-family: Arial, sans-serif;
      font-size: 14px;
      text-anchor: middle;
      font-weight: 600;
    }
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