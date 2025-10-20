import DefaultTheme from 'vitepress/theme'
import './style.css'
import { h } from 'vue'
import ShareRow from '../../components/share_row.vue'
import Layout from './Layout.vue'

export default {
    extends: DefaultTheme,
    Layout
}