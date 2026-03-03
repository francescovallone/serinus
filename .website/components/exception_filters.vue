<script setup>
</script>

<template>
	<svg width="690" height="400" xmlns="http://www.w3.org/2000/svg">
		<path d="M165 180 C165 180, 165 180, 515 180" class="arrow top-arrow"/>
    <path d="M165 180 C165 180, 165 180, 515 180" class="arrow mid-arrow"/>

    <path d="M590 150 C590 110, 590 110, 415 110" class="arrow top-arrow"/>
    <path d="M590 150 C590 110, 590 110, 415 110" class="arrow mid-arrow"/>
    <text x="450" y="90" style="fill:#aaa; font-size:12px;">HTTP Exception</text>

    <path d="M265 110 C85 110, 85 110, 85 150" class="arrow top-arrow"/>
    <path d="M265 110 C85 110, 85 110, 85 150" class="arrow mid-arrow"/>
    <!-- Client Side box -->
		<rect x="5" y="145" width="160" height="70" class="box stroke" style="stroke-width: 1; fill: white;"/>
		<rect x="10" y="150" width="150" height="60" class="box stroke"/>
		<text x="85" y="185" class="text-brand">Client Side</text>
		
		<rect x="265" y="80" width="150" height="60" class="box"/>
		<text x="340" y="115" class="text">Exception Filters</text>

		<rect x="515" y="150" width="150" height="60" class="box stroke" style="fill: white;"/>
		<text x="590" y="185" class="text-brand">Route</text>
	</svg>
</template>

<!-- Styles -->
<style scoped>
    .box {
      font-size: 16px;
      font-family: sans-serif;
      fill: var(--vp-c-brand-1);
      stroke: none;
      fill-opacity: 1;
    }
    .box.stroke {
	  fill : white;
      stroke: var(--vp-c-brand-1);
      stroke-width: 2;
      fill: transparent
    }
    .text {
      fill: var(--primary-foreground);;
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
	.move-square {
	  fill: white;
	  stroke: var(--vp-c-brand-1);
	  stroke-width: 2;
	  animation: move 2s ease-in forwards;
	  animation-iteration-count: infinite;
	}
	.move-circle {
	  fill: white;
	  stroke: var(--vp-c-brand-1);
	  stroke-width: 2;
	  animation: move-circle 2s ease-in forwards;
	  animation-iteration-count: infinite;
	  animation-delay: 1.5s;
	}
	@keyframes move {
	  0% {
		transform: translateX(-16px);
	  }
	  100% {
		transform: translateX(116px);
	  }
	}
	@keyframes move-circle {
	  0% {
		transform: translateX(-16px);
	  }
	  100% {
		transform: translateX(116px);
	  }
	}
	@keyframes dash {
      to {
        stroke-dashoffset: 0;
      }
    }
  </style>