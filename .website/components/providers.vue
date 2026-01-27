<script setup>
</script>

<template>
	<svg width="688" height="400" xmlns="http://www.w3.org/2000/svg">
    	<rect x="50" y="50" width="150" height="60" class="box"/>
		<text x="125" y="85" class="text">Service</text>
		<rect x="270" y="50" width="150" height="60" class="box"/>
		<text x="345" y="85" class="text">Connection</text>
		<rect x="490" y="50" width="150" height="60" class="box"/>
		<text x="565" y="85" class="text">Service</text>

		<rect x="160" y="140" width="150" height="60" class="box"/>
		<path d="M120 110 C120 165, 120 165, 160 165" class="arrow top-arrow"/>
		<path d="M345 110 C345 165, 345 165, 310 165" class="arrow top-arrow"/>
		<text x="235" y="175" class="text">Service</text>

		<rect x="490" y="140" width="150" height="60" class="box"/>
		<path d="M565 110 C565 140, 565 140, 564 140" class="arrow top-arrow"/>
		<text x="565" y="175" class="text">Provider</text>

		<rect x="270" y="230" width="150" height="60" class="box stroke"/>
		<path d="M235 200 C235 260, 235 260, 270 260" class="arrow top-arrow"/>
		<path d="M565 200 C565 260, 565 260, 420 260" class="arrow top-arrow"/>
		<text x="345" y="265" class="text-brand">Scoped Context</text>
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
      font-size: 14px;
      text-anchor: middle;
      font-weight: 600;
    }
    .text-brand {
      fill: var(--vp-c-brand-1);
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