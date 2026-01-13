import DefaultTheme from 'vitepress/theme'
import './style.css'
import Layout from './layout.vue'
import { EnhanceAppContext } from 'vitepress'

export default {
    extends: DefaultTheme,
    Layout,
    enhanceApp(ctx: EnhanceAppContext) {
        DefaultTheme?.enhanceApp?.(ctx)
    }
}