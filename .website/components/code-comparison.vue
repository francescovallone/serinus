<script setup lang="ts">
	
</script>
<template>
	<div class="grid gap-2 lg:gap-2 md:grid-cols-2 items-stretch compare">
  		<div class="flex flex-col code-limiter border-2 bg-card justify-between">
			<header class="border-b-2 p-2 font-display font-semibold text-sm text-muted-foreground truncate">
				<slot name="leftHeader" slot="leftHeader" />
			</header>
			<slot name="leftCode" slot="leftCode" />
			<footer class="border-t-2 p-2 bg-muted/30 text-sm text-muted-foreground leading-relaxed">
				<slot name="leftFooter" slot="leftFooter" />
			</footer>
		</div>
		<div class="flex flex-col code-limiter border-2 bg-card justify-between">
			<header class="border-b-2 p-2 font-display font-semibold text-sm text-muted-foreground truncate">
				<slot name="rightHeader" slot="rightHeader" />
			</header>
			<slot name="rightCode" slot="rightCode" />
			<footer class="border-t-2 p-2 bg-muted/30 text-sm text-muted-foreground leading-relaxed">
				<slot name="rightFooter" slot="rightFooter" />
			</footer>
		</div>
	</div>
</template>

<style>
.compare div[class*="language-"]:not(.vp-code-group div[class*="language-"]) {
	border-width: 0px;
}
.compare [class*="language-"]:not(.vp-doc .vp-code) > span.lang {
	display: none;
}
.compare > .code-limiter, .compare > .code-limiter > header, .compare > .code-limiter > footer {
	border-color: hsl(var(--border));
}
</style>