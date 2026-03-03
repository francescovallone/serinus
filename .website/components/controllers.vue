<script setup>
import DiagramCanvas from './ui/diagram/DiagramCanvas.vue';
import DiagramBox from './ui/diagram/DiagramBox.vue';
import DiagramArrow from './ui/diagram/DiagramArrow.vue';
import DiagramText from './ui/diagram/DiagramText.vue';
</script>

<template>
	<DiagramCanvas>
    <!-- Client Side box -->
    <DiagramBox x="50" y="150" width="150" height="60" variant="stroke" label="Client Side" labelVariant="brand" />
    <DiagramBox x="45" y="145" width="160" height="70" variant="stroke" customStyle="stroke-width: 1;" />

    <!-- Dashed arrow (HTTP request) -->
    <DiagramArrow :x1="205" y1="180" :x2="340" y2="180" dashed />
    <DiagramText x="270" y="165" variant="muted">HTTP request</DiagramText>

    <!-- Controller boxes -->
    <!-- Top Controller -->
    <DiagramBox x="460" y="80" width="170" height="60" label="Controller" />

    <!-- Middle Controller (highlighted) -->
    <DiagramBox x="460" y="150" width="170" height="60" label="Controller" />

    <!-- Bottom Controller -->
    <DiagramBox x="460" y="220" width="170" height="60" label="Controller" />

    <!-- curved path from first line to the top-most controller -->
    <DiagramArrow d="M340 180 C340 100, 340 110, 460 110" animated />
    <!-- curved path from first line to the middle controller -->
    <DiagramArrow d="M340 180 C340 180, 340 180, 460 180" animated />
    <!-- curved path from first line to the bottom controller -->
    <DiagramArrow d="M340 180 C340 250, 340 250, 460 250" animated />
  </DiagramCanvas>
</template>
