import DefaultTheme from 'vitepress/theme'
import './style.css'
import Layout from './layout.vue'
import { EnhanceAppContext } from 'vitepress'
import '@avesbox/canary/style.css'
import { setupCanaryTheme } from '@avesbox/canary'

export default {
    extends: DefaultTheme,
    Layout,
    enhanceApp(ctx: EnhanceAppContext) {
        setupCanaryTheme(ctx.app)
        DefaultTheme?.enhanceApp?.(ctx)
    }
}