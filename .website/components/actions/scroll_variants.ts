import { useInView } from "motion-v";
import { ref, type Ref } from "vue";

interface ScrollAnimationOptions {
  threshold?: number;
  once?: boolean;
}

export const useScrollAnimation = (options: ScrollAnimationOptions = {}) => {
  const { threshold = 0.2, once = true } = options;
  const target = ref<HTMLElement | null>(null);
  const isInView = useInView(target as Ref<HTMLElement | null>, {
    amount: threshold,
    once,
  });

  return { target, isInView };
};

export const scrollVariants = {
  fadeUp: {
    hidden: { opacity: 0, y: 40 },
    visible: { opacity: 1, y: 0 },
  },
  fadeIn: {
    hidden: { opacity: 0 },
    visible: { opacity: 1 },
  },
  slideLeft: {
    hidden: { opacity: 0, x: -40 },
    visible: { opacity: 1, x: 0 },
  },
  slideRight: {
    hidden: { opacity: 0, x: 40 },
    visible: { opacity: 1, x: 0 },
  },
  scaleIn: {
    hidden: { opacity: 0, scale: 0.9 },
    visible: { opacity: 1, scale: 1 },
  },
  stagger: {
    visible: {
      transition: {
        staggerChildren: 0.1,
      },
    },
  },
};
