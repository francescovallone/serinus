<script setup>
</script>

<template>
	<svg width="690" height="400" xmlns="http://www.w3.org/2000/svg">
    <circle cx="50%" cy="50%" r="160" style="fill: transparent; stroke: #aaa; stroke-width: 1px;" />
    <rect x="140" y="70" width="150" height="60" class="box"/>
		<text x="215" y="105" class="text">Permission</text>
    <rect x="140" y="270" width="150" height="60" class="box"/>
		<text x="215" y="305" class="text">User</text>


		<rect x="400" y="70" width="150" height="60" class="box"/>
		<text x="475" y="105" class="text">Guarded</text>
    <rect x="400" y="270" width="150" height="60" class="box"/>
		<text x="475" y="305" class="text">AuthStrategy</text>

		<rect x="270" y="170" width="150" height="60" class="box stroke"/>
		<text x="345" y="205" class="text-brand">Route</text>
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
    @keyframes dash {
      to {
        stroke-dashoffset: 0;
      }
    }
  </style>