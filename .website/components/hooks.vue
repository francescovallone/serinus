<script setup>
</script>

<template>
	<svg width="688" height="400" xmlns="http://www.w3.org/2000/svg">
		<rect x="50" y="50" width="150" height="60" class="box stroke"/>
    	<rect x="45" y="45" width="160" height="70" class="box stroke" style="stroke-width: 1;"/>
    	<text x="125" y="85" class="text-brand">Client Side</text>


		<path d="M205 80 C205 80, 205 80, 460 80" class="arrow top-arrow"/>
    	<path d="M205 80 C205 80, 205 80, 460 80" class="arrow mid-arrow"/>

		<rect x="460" y="50" width="150" height="60" class="box"/>
    	<text x="535" y="85" class="text">OnRequest</text>

		<path d="M535 110 C535 110, 535 110, 535 160" class="arrow top-arrow"/>
		<path d="M535 110 C535 110, 535 110, 535 160" class="arrow mid-arrow"/>

		<rect x="460" y="160" width="150" height="60" class="box"/>
		<text x="535" y="195" class="text">BeforeHandle</text>

		<path d="M205 190 C205 190, 205 190, 460 190" class="arrow top-arrow"/>
		<path d="M205 190 C205 190, 205 190, 460 190" class="arrow mid-reverse-arrow"/>

		<rect x="50" y="160" width="150" height="60" class="box stroke"/>
		<text x="125" y="195" class="text-brand">Handler</text>

		<path d="M125 220 C125 220, 125 220, 125 270" class="arrow top-arrow"/>
		<path d="M125 220 C125 220, 125 220, 125 270" class="arrow mid-arrow"/>

		<rect x="50" y="270" width="150" height="60" class="box"/>
		<text x="125" y="305" class="text">AfterHandle</text>

		<path d="M205 300 C205 300, 205 300, 460 300" class="arrow top-arrow"/>
		<path d="M205 300 C205 300, 205 300, 460 300" class="arrow mid-arrow"/>
		<rect x="460" y="270" width="150" height="60" class="box"/>
		<text x="535" y="305" class="text">OnResponse</text>
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
	.mid-reverse-arrow {
	  stroke-dasharray: 10, 40;
	  stroke-dashoffset: 0;
	  stroke-linejoin: bevel;
	  animation: dash-reverse 3s linear forwards;
	  animation-iteration-count: infinite;
	  stroke: var(--vp-c-brand-1);
	}
	@keyframes dash-reverse {
	  to {
		stroke-dashoffset: 200;
	  }
	}
    @keyframes dash {
      to {
        stroke-dashoffset: 0;
      }
    }
  </style>