<script setup>
</script>

<template>
	<svg width="688" height="400" xmlns="http://www.w3.org/2000/svg">
    	<rect x="270" y="230" width="150" height="60" class="box"/>
		<path d="M345 200 C345 200, 345 200, 345 230" class="arrow top-arrow"/>
		<text x="345" y="265" class="text">Database Module</text>

		<rect x="50" y="140" width="150" height="60" class="box"/>
		<path d="M125 140 C125 80, 125 80, 270 80" class="arrow top-arrow"/>
		<text x="125" y="175" class="text">Config Module</text>
		<rect x="270" y="140" width="150" height="60" class="box"/>
		<path d="M345 140 C345 110, 345 110, 345 110" class="arrow top-arrow"/>
		<text x="345" y="175" class="text">Feature Module</text>

		<rect x="490" y="140" width="150" height="60" class="box"/>
		<path d="M420 80 C565 80, 565 80, 565 140" class="arrow top-arrow"/>
		<text x="565" y="175" class="text">Auth Module</text>

		<rect x="270" y="50" width="150" height="60" class="box stroke"/>
		<text x="345" y="85" class="text-brand">Entrypoint</text>
  	</svg>
</template>

<!-- Styles -->
<style scoped>
    .box {
      font-size: 16px;
      font-family: sans-serif;
      fill: hsl(var(--primary));
      stroke: none;
      fill-opacity: 1;
    }
    .box.stroke {
      stroke: hsl(var(--primary));
      stroke-width: 2;
      fill: transparent
    }
    .text {
      fill: hsl(var(--primary-foreground));
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