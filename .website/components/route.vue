<script setup>
</script>

<template>
	<svg width="688" height="400" xmlns="http://www.w3.org/2000/svg">
    <rect x="50" y="150" width="150" height="60" class="box stroke"/>
    <text x="125" y="185" class="text-brand">Controller</text>

    <!-- Dashed arrow (HTTP request) -->
    <line x1="205" y1="180" x2="340" y2="180" class="arrow arrow-dashed">
      <animate
          attributeName="stroke-dashoffset"
          values="100;0"
          dur="3s"
          calcMode="linear"
          repeatCount="indefinite" />
    </line>
    <text x="270" y="165" class="text" style="fill:#aaa; font-size:12px;">GET /</text>

    <!-- Controller boxes -->
    <!-- Top Controller -->
    <rect x="460" y="80" width="150" height="60" class="box"/>
    <text x="535" y="115" class="text">GET /</text>

    <!-- Middle Controller (highlighted) -->
    <rect x="460" y="150" width="150" height="60" class="box"/>
    <text x="535" y="185" class="text">POST /</text>

    <!-- Bottom Controller -->
    <rect x="460" y="220" width="150" height="60" class="box"/>
    <text x="535" y="255" class="text">PUT /</text>

    <!-- curved path from first line to the top-most controller -->
    <path d="M340 180 C340 100, 340 110, 460 110" class="arrow top-arrow"/>
    <path d="M340 180 C340 100, 340 110, 460 110" class="arrow mid-arrow"/>
    <!-- curved path from first line to the middle controller -->
    <path d="M340 180 C340 180, 340 180, 460 180" class="arrow top-arrow"/>
    <!-- curved path from first line to the bottom controller -->
    <path d="M340 180 C340 250, 340 250, 460 250" class="arrow top-arrow"/>
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