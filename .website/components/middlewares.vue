<script setup>
</script>

<template>
	<svg width="690" height="400" xmlns="http://www.w3.org/2000/svg">
    <!-- Client Side box -->
    <rect x="10" y="150" width="150" height="60" class="box stroke" rx="8" ry="8"/>
    <rect x="5" y="145" width="160" height="70" class="box stroke" rx="12" ry="12" style="stroke-width: 1;"/>
    <text x="85" y="185" class="text-brand">Client Side</text>

    <!-- Dashed arrow (HTTP request) -->
    <line x1="165" y1="180" x2="250" y2="180" class="arrow arrow-dashed">
      <animate
          attributeName="stroke-dashoffset"
          values="100;0"
          dur="3s"
          calcMode="linear"
          repeatCount="indefinite" />
    </line>
    <text x="205" y="165" class="text" style="fill:#aaa; font-size:12px;">Request</text>
    <rect x="250" y="150" width="170" height="60" class="box" rx="12" ry="12"/>
    <text x="335" y="185" class="text">Middleware</text>
    <path d="M420 180 C420 180, 420 180, 515 180" class="arrow top-arrow"/>
    <path d="M420 180 C420 180, 420 180, 515 180" class="arrow mid-arrow"/>

    <rect x="515" y="150" width="170" height="60" class="box stroke" rx="12" ry="12"/>
    <text x="600" y="185" class="text-brand">Route</text>
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