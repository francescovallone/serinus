<script setup>
</script>

<template>
	<svg width="688" height="400" xmlns="http://www.w3.org/2000/svg">
    <!-- Client Side box -->
    <rect x="50" y="150" width="150" height="60" class="box stroke"/>
    <rect x="45" y="145" width="160" height="70" class="box stroke" style="stroke-width: 1;"/>
    <text x="125" y="185" class="text-brand">Client Side</text>

    <!-- Dashed arrow (HTTP request) -->
    <line x1="205" y1="180" x2="340" y2="180" class="arrow arrow-dashed">
      <animate
          attributeName="stroke-dashoffset"
          values="100;0"
          dur="3s"
          calcMode="linear"
          repeatCount="indefinite" />
    </line>
    <text x="270" y="165" class="text" style="fill:#aaa; font-size:12px;">HTTP request</text>

    <!-- Controller boxes -->
    <!-- Top Controller -->
    <rect x="460" y="80" width="170" height="60" class="box"/>
    <text x="545" y="115" class="text">Controller</text>

    <!-- Middle Controller (highlighted) -->
    <rect x="460" y="150" width="170" height="60" class="box"/>
    <text x="545" y="185" class="text">Controller</text>

    <!-- Bottom Controller -->
    <rect x="460" y="220" width="170" height="60" class="box"/>
    <text x="545" y="255" class="text">Controller</text>

    <!-- curved path from first line to the top-most controller -->
    <path d="M340 180 C340 100, 340 110, 460 110" class="arrow top-arrow"/>
    <path d="M340 180 C340 100, 340 110, 460 110" class="arrow mid-arrow"/>
    <!-- curved path from first line to the middle controller -->
    <path d="M340 180 C340 180, 340 180, 460 180" class="arrow top-arrow"/>
    <path d="M340 180 C340 180, 340 180, 460 180" class="arrow mid-arrow"/>
    <!-- curved path from first line to the bottom controller -->
    <path d="M340 180 C340 250, 340 250, 460 250" class="arrow top-arrow"/>
    <path d="M340 180 C340 250, 340 250, 460 250" class="arrow mid-arrow"/>
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
      fill: var(--primary-foreground);
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