<script setup>
</script>

<template>
	<svg width="690" height="400" xmlns="http://www.w3.org/2000/svg">
    <!-- Client Side box -->
    <rect x="10" y="150" width="150" height="60" class="box stroke"/>
    <rect x="5" y="145" width="160" height="70" class="box stroke" style="stroke-width: 1;"/>
    <text x="85" y="185" class="text-brand">Client Side</text>

    <!-- Dashed arrow (HTTP request) -->
    <line x1="165" y1="180" x2="265" y2="180" class="arrow arrow-dashed">
      <animate
          attributeName="stroke-dashoffset"
          values="100;0"
          dur="3s"
          calcMode="linear"
          repeatCount="indefinite" />
    </line>
    <text x="215" y="165" class="text" style="fill:#aaa; font-size:12px;">Request</text>
    <rect x="265" y="150" width="150" height="60" class="box"/>
    <text x="340" y="185" class="text">Middleware</text>
    <path d="M415 180 C415 180, 415 180, 515 180" class="arrow top-arrow"/>
    <path d="M415 180 C415 180, 415 180, 515 180" class="arrow mid-arrow"/>

    <rect x="515" y="150" width="150" height="60" class="box stroke"/>
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