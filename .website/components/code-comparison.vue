<script setup lang="ts">
import { computed, ref } from 'vue'

const currentVisible = ref<'left' | 'right'>('left')
const values = ['left', 'right'] as const
const activeIndex = computed(() => (currentVisible.value === 'left' ? 0 : 1))
</script>

<template>
  <div class="compare border-2 bg-card overflow-hidden" aria-label="Code comparison" style="border-color: hsl(var(--border));">
    <div class="tab-bar relative flex border-b-2 p-2" style="border-color: hsl(var(--border));">
      <button
        v-for="value in values"
        :key="value"
        type="button"
        @click="currentVisible = value"
        :class="[
          'relative flex-1 px-5 py-3 text-center font-display font-semibold text-sm transition-colors',
          currentVisible === value
            ? 'text-foreground'
            : 'text-muted-foreground hover:text-foreground/70'
        ]"
      >
        <span class="flex items-center justify-center gap-2 capitalize">
          <slot :name="`${value}Header`" />
        </span>
      </button>
      <span
        class="tab-indicator absolute bottom-0 left-0 h-0.5 bg-primary"
        :style="{ transform: `translateX(${activeIndex * 100}%)` }"
      />
    </div>

    <Transition name="fade-slide" mode="out-in">
      <div
        :key="currentVisible"
        class="flex flex-col code-limiter justify-between"
      >
        <slot v-if="currentVisible === 'left'" name="leftCode" />
        <slot v-else name="rightCode" />
        <footer class="border-t-2 p-2 bg-muted/30 text-sm text-muted-foreground leading-relaxed">
          <slot v-if="currentVisible === 'left'" name="leftFooter" />
          <slot v-else name="rightFooter" />
        </footer>
      </div>
    </Transition>
  </div>
</template>

<style>
.compare div[class*="language-"]:not(.vp-code-group div[class*="language-"]) {
  border-width: 0px;
}

.compare [class*="language-"]:not(.vp-doc .vp-code) > span.lang {
  display: none;
}

.compare > .code-limiter,
.compare > .code-limiter > header,
.compare > .code-limiter > footer {
  border-color: hsl(var(--border));
}

.tab-indicator {
  width: 50%;
  transition: transform 0.24s ease;
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: opacity 0.22s ease, transform 0.22s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(4px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
