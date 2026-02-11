import { defineComponent, h } from 'vue';

const CopyIcon = defineComponent({
	name: 'CopyIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M9 15c0-2.828 0-4.243.879-5.121C10.757 9 12.172 9 15 9h1c2.828 0 4.243 0 5.121.879C22 10.757 22 12.172 22 15v1c0 2.828 0 4.243-.879 5.121C20.243 22 18.828 22 16 22h-1c-2.828 0-4.243 0-5.121-.879C9 20.243 9 18.828 9 16z' }),
		h('path', { d: 'M17 9c-.003-2.957-.047-4.489-.908-5.538a4 4 0 0 0-.554-.554C14.43 2 12.788 2 9.5 2c-3.287 0-4.931 0-6.038.908a4 4 0 0 0-.554.554C2 4.57 2 6.212 2 9.5c0 3.287 0 4.931.908 6.038a4 4 0 0 0 .554.554c1.05.86 2.58.906 5.538.908' })
	])
});


const ShieldIcon = defineComponent({
	name: 'ShieldIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z' })
	])
});

const LightningIcon = defineComponent({
	name: 'LightningIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('polygon', { points: '13 2 3 14 12 14 11 22 21 10 12 10 13 2' })
	])
});

const SettingsIcon = defineComponent({
	name: 'SettingsIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M14 17H5M19 7h-9' }),
		h('circle', { cx: '17', cy: '17', r: '3' }),
		h('circle', { cx: '7', cy: '7', r: '3' })
	])
})

const RadioIcon = defineComponent({
	name: 'RadioIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M16.247 7.761a6 6 0 0 1 0 8.478m2.828-11.306a10 10 0 0 1 0 14.134m-14.15 0a10 10 0 0 1 0-14.134m2.828 11.306a6 6 0 0 1 0-8.478' }),
		h('circle', { cx: '12', cy: '12', r: '2' })
	])
});

const PuzzleIcon = defineComponent({
	name: 'TerminalIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M15.39 4.39a1 1 0 0 0 1.68-.474a2.5 2.5 0 1 1 3.014 3.015a1 1 0 0 0-.474 1.68l1.683 1.682a2.414 2.414 0 0 1 0 3.414L19.61 15.39a1 1 0 0 1-1.68-.474a2.5 2.5 0 1 0-3.014 3.015a1 1 0 0 1 .474 1.68l-1.683 1.682a2.414 2.414 0 0 1-3.414 0L8.61 19.61a1 1 0 0 0-1.68.474a2.5 2.5 0 1 1-3.014-3.015a1 1 0 0 0 .474-1.68l-1.683-1.682a2.414 2.414 0 0 1 0-3.414L4.39 8.61a1 1 0 0 1 1.68.474a2.5 2.5 0 1 0 3.014-3.015a1 1 0 0 1-.474-1.68l1.683-1.682a2.414 2.414 0 0 1 3.414 0z' }),
	])
});

const CodeFile = defineComponent({
	name: 'CodeFile',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M4 12.15V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.706.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2h-3.35' }),
		h('path', { d: 'M14 2v5a1 1 0 0 0 1 1h5M5 16l-3 3l3 3m4 0l3-3l-3-3' })
	])
});

const CogIcon = defineComponent({
	name: 'CogIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M9.671 4.136a2.34 2.34 0 0 1 4.659 0a2.34 2.34 0 0 0 3.319 1.915a2.34 2.34 0 0 1 2.33 4.033a2.34 2.34 0 0 0 0 3.831a2.34 2.34 0 0 1-2.33 4.033a2.34 2.34 0 0 0-3.319 1.915a2.34 2.34 0 0 1-4.659 0a2.34 2.34 0 0 0-3.32-1.915a2.34 2.34 0 0 1-2.33-4.033a2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915' }),
		h('circle', { cx: '12', cy: '12', r: '3' }),
	])
});

const BracesFile = defineComponent({
	name: 'BracesFile',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z' }),
		h('path', { d: 'M14 2v5a1 1 0 0 0 1 1h5m-10 4a1 1 0 0 0-1 1v1a1 1 0 0 1-1 1a1 1 0 0 1 1 1v1a1 1 0 0 0 1 1m4 0a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1a1 1 0 0 1-1-1v-1a1 1 0 0 0-1-1' })
	])
});

const TestTubeIcon = defineComponent({
	name: 'TestTubeIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M21 7L6.82 21.18a2.83 2.83 0 0 1-3.99-.01a2.83 2.83 0 0 1 0-4L17 3m-1-1l6 6m-10 8H4' })
	])
});

const ClockIcon = defineComponent({
	name: 'ClockIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M12 6v6l4 2' }),
		h('circle', { cx: '12', cy: '12', r: '10' })
	])
});

const ShieldCheckIcon = defineComponent({
	name: 'ShieldCheckIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z' }),
		h('path', { d: 'm9 12l2 2l4-4' })
	])
});

const XSocialIcon = defineComponent({
	name: 'XSocialIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 16 16',
		fill: 'currentColor',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'm9.237 7.004l4.84-5.505H12.93L8.727 6.28L5.371 1.5H1.5l5.075 7.228L1.5 14.499h1.147l4.437-5.047l3.545 5.047H14.5zM7.666 8.791l-.514-.72L3.06 2.344h1.762l3.302 4.622l.514.72l4.292 6.007h-1.761z' })
	])
});

const GithubIcon = defineComponent({
	name: 'GithubIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'currentColor',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M10 20.568c-3.429 1.157-6.286 0-8-3.568' }),
		h('path', { d: 'M10 22v-3.242c0-.598.184-1.118.48-1.588c.204-.322.064-.78-.303-.88C7.134 15.452 5 14.107 5 9.645c0-1.16.38-2.25 1.048-3.2c.166-.236.25-.354.27-.46c.02-.108-.015-.247-.085-.527c-.283-1.136-.264-2.343.16-3.43c0 0 .877-.287 2.874.96c.456.285.684.428.885.46s.469-.035 1.005-.169A9.5 9.5 0 0 1 13.5 3a9.6 9.6 0 0 1 2.343.28c.536.134.805.2 1.006.169c.2-.032.428-.175.884-.46c1.997-1.247 2.874-.96 2.874-.96c.424 1.087.443 2.294.16 3.43c-.07.28-.104.42-.084.526s.103.225.269.461c.668.95 1.048 2.04 1.048 3.2c0 4.462-2.134 5.807-5.177 6.643c-.367.101-.507.559-.303.88c.296.47.48.99.48 1.589V22' })
	])
});

const MessageIcon = defineComponent({
	name: 'MessageIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'm3 20l1.3-3.9C1.976 12.663 2.874 8.228 6.4 5.726c3.526-2.501 8.59-2.296 11.845.48c3.255 2.777 3.695 7.266 1.029 10.501S11.659 20.922 7.7 19z', 'stroke-linecap': 'round' }),
	])
});

const DiscordIcon = defineComponent({
	name: 'DiscordIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'currentColor',
		class: 'w-5 h-5'
	}, [
		h('path', { d: "M19.27 5.33C17.94 4.71 16.5 4.26 15 4a.1.1 0 0 0-.07.03c-.18.33-.39.76-.53 1.09a16.1 16.1 0 0 0-4.8 0c-.14-.34-.35-.76-.54-1.09c-.01-.02-.04-.03-.07-.03c-1.5.26-2.93.71-4.27 1.33c-.01 0-.02.01-.03.02c-2.72 4.07-3.47 8.03-3.1 11.95c0 .02.01.04.03.05c1.8 1.32 3.53 2.12 5.24 2.65c.03.01.06 0 .07-.02c.4-.55.76-1.13 1.07-1.74c.02-.04 0-.08-.04-.09c-.57-.22-1.11-.48-1.64-.78c-.04-.02-.04-.08-.01-.11c.11-.08.22-.17.33-.25c.02-.02.05-.02.07-.01c3.44 1.57 7.15 1.57 10.55 0c.02-.01.05-.01.07.01c.11.09.22.17.33.26c.04.03.04.09-.01.11c-.52.31-1.07.56-1.64.78c-.04.01-.05.06-.04.09c.32.61.68 1.19 1.07 1.74c.03.01.06.02.09.01c1.72-.53 3.45-1.33 5.25-2.65c.02-.01.03-.03.03-.05c.44-4.53-.73-8.46-3.1-11.95c-.01-.01-.02-.02-.04-.02M8.52 14.91c-1.03 0-1.89-.95-1.89-2.12s.84-2.12 1.89-2.12c1.06 0 1.9.96 1.89 2.12c0 1.17-.84 2.12-1.89 2.12m6.97 0c-1.03 0-1.89-.95-1.89-2.12s.84-2.12 1.89-2.12c1.06 0 1.9.96 1.89 2.12c0 1.17-.83 2.12-1.89 2.12" })
	])
});


const TerminalIcon = defineComponent({
	name: 'TerminalIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'm7 7l1.227 1.057C8.742 8.502 9 8.724 9 9s-.258.498-.773.943L7 11m4 0h3' }),
		h('path', { d: 'M12 21c3.75 0 5.625 0 6.939-.955a5 5 0 0 0 1.106-1.106C21 17.625 21 15.749 21 12s0-5.625-.955-6.939a5 5 0 0 0-1.106-1.106C17.625 3 15.749 3 12 3s-5.625 0-6.939.955A5 5 0 0 0 3.955 5.06C3 6.375 3 8.251 3 12s0 5.625.955 6.939a5 5 0 0 0 1.106 1.106C6.375 21 8.251 21 12 21' })
	])
});

const CalendarIcon = defineComponent({
	name: 'CalendarIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M4 7a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zm12-4v4M8 3v4m-4 4h16' }),
		h('path', { d: 'M8 15h2v2H8z' })
	])
});

const ArrowUpRightIcon = defineComponent({
	name: 'ArrowUpRightIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M17 7L7 17M8 7h9v9' })
	])
});

const LinkedInSocialIcon = defineComponent({
	name: 'LinkedInSocialIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'currentColor',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M7.5 9h-4a.5.5 0 0 0-.5.5v12a.5.5 0 0 0 .5.5h4a.5.5 0 0 0 .5-.5v-12a.5.5 0 0 0-.5-.5M7 21H4V10h3zM18 9c-1.085 0-2.14.358-3 1.019V9.5a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 0-.5.5v12a.5.5 0 0 0 .5.5h4a.5.5 0 0 0 .5-.5V16a1.5 1.5 0 1 1 3 0v5.5a.5.5 0 0 0 .5.5h4a.5.5 0 0 0 .5-.5V14a5.006 5.006 0 0 0-5-5m4 12h-3v-5a2.5 2.5 0 1 0-5 0v5h-3V10h3v1.203a.5.5 0 0 0 .89.313A3.983 3.983 0 0 1 22 14zM5.868 2.002A3 3 0 0 0 5.515 2a2.74 2.74 0 0 0-2.926 2.729a2.71 2.71 0 0 0 2.869 2.728h.028a2.734 2.734 0 1 0 .382-5.455M5.833 6.46q-.173.016-.347-.003h-.028A1.736 1.736 0 1 1 5.515 3a1.737 1.737 0 0 1 .318 3.46' })
	])
});

const LinkIcon = defineComponent({
	name: 'LinkIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'm9 15l6-6m-4-3l.463-.536a5 5 0 0 1 7.071 7.072L18 13m-5 5l-.397.534a5.07 5.07 0 0 1-7.127 0a4.97 4.97 0 0 1 0-7.071L6 11' })
	])
});

const ChatGptIcon = defineComponent({
	name: 'ChatGptIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 256 256',
		fill: 'currentColor',
		class: 'w-5 h-5',
	}, [
		h('path', { d: 'M239.184 106.203a64.716 64.716 0 0 0-5.576-53.103C219.452 28.459 191 15.784 163.213 21.74A65.586 65.586 0 0 0 52.096 45.22a64.716 64.716 0 0 0-43.23 31.36c-14.31 24.602-11.061 55.634 8.033 76.74a64.665 64.665 0 0 0 5.525 53.102c14.174 24.65 42.644 37.324 70.446 31.36a64.72 64.72 0 0 0 48.754 21.744c28.481.025 53.714-18.361 62.414-45.481a64.767 64.767 0 0 0 43.229-31.36c14.137-24.558 10.875-55.423-8.083-76.483Zm-97.56 136.338a48.397 48.397 0 0 1-31.105-11.255l1.535-.87 51.67-29.825a8.595 8.595 0 0 0 4.247-7.367v-72.85l21.845 12.636c.218.111.37.32.409.563v60.367c-.056 26.818-21.783 48.545-48.601 48.601Zm-104.466-44.61a48.345 48.345 0 0 1-5.781-32.589l1.534.921 51.722 29.826a8.339 8.339 0 0 0 8.441 0l63.181-36.425v25.221a.87.87 0 0 1-.358.665l-52.335 30.184c-23.257 13.398-52.97 5.431-66.404-17.803ZM23.549 85.38a48.499 48.499 0 0 1 25.58-21.333v61.39a8.288 8.288 0 0 0 4.195 7.316l62.874 36.272-21.845 12.636a.819.819 0 0 1-.767 0L41.353 151.53c-23.211-13.454-31.171-43.144-17.804-66.405v.256Zm179.466 41.695-63.08-36.63L161.73 77.86a.819.819 0 0 1 .768 0l52.233 30.184a48.6 48.6 0 0 1-7.316 87.635v-61.391a8.544 8.544 0 0 0-4.4-7.213Zm21.742-32.69-1.535-.922-51.619-30.081a8.39 8.39 0 0 0-8.492 0L99.98 99.808V74.587a.716.716 0 0 1 .307-.665l52.233-30.133a48.652 48.652 0 0 1 72.236 50.391v.205ZM88.061 139.097l-21.845-12.585a.87.87 0 0 1-.41-.614V65.685a48.652 48.652 0 0 1 79.757-37.346l-1.535.87-51.67 29.825a8.595 8.595 0 0 0-4.246 7.367l-.051 72.697Zm11.868-25.58 28.138-16.217 28.188 16.218v32.434l-28.086 16.218-28.188-16.218-.052-32.434Z' }),	
	])
});

const ClaudeIcon = defineComponent({
	name: 'ClaudeIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'currentColor',
		class: 'w-5 h-5',
	}, [
		h('path', { d: 'm12.594 23.258l-.012.002l-.071.035l-.02.004l-.014-.004l-.071-.036q-.016-.004-.024.006l-.004.01l-.017.428l.005.02l.01.013l.104.074l.015.004l.012-.004l.104-.074l.012-.016l.004-.017l-.017-.427q-.004-.016-.016-.018m.264-.113l-.014.002l-.184.093l-.01.01l-.003.011l.018.43l.005.012l.008.008l.201.092q.019.005.029-.008l.004-.014l-.034-.614q-.005-.019-.02-.022m-.715.002a.02.02 0 0 0-.027.006l-.006.014l-.034.614q.001.018.017.024l.015-.002l.201-.093l.01-.008l.003-.011l.018-.43l-.003-.012l-.01-.01z' }),
		h('path', { d: 'M13.604 2.006a1 1 0 0 1 .89 1.099l-.643 6.104l3.868-4.834a1 1 0 0 1 1.562 1.25l-4.19 5.237l5.68-1.336a1.001 1.001 0 0 1 .458 1.948l-3.77.886l3.715.656a1 1 0 1 1-.348 1.968l-4.901-.865l4.225 3.622a.999.999 0 1 1-1.3 1.518l-2.324-1.991l1.331 2.217a1 1 0 0 1-1.715 1.03l-2.992-4.988l-.657 5.59a1 1 0 0 1-1.986-.234l.556-4.732l-3.256 4.44a1 1 0 0 1-1.614-1.183l2.564-3.497l-3.242 1.947a1 1 0 0 1-1.03-1.715l4.693-2.817L2.948 13a1 1 0 0 1 .105-1.998l6.218.327L3.901 7.3A1 1 0 1 1 5.1 5.7l4.446 3.335l-2.93-5.57a1 1 0 0 1 1.769-.93l3.466 6.584l.655-6.223a1 1 0 0 1 1.098-.89' })
	])
});

const MarkdownIcon = defineComponent({
	name: 'MarkdownIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
		class: 'w-5 h-5'
	}, [
		h('path', { d: 'M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z' }),
		h('path', { d: 'M7 15V9l2 2l2-2v6m3-2l2 2l2-2m-2 2V9' })
	])
});

const HeartIcon = defineComponent({
	name: 'HeartIcon',
	setup: () => () => h('svg', {
		viewBox: '0 0 24 24',
		fill: 'none',
		stroke: 'currentColor',
		'stroke-width': '2',
		'stroke-linecap': 'round',
		'stroke-linejoin': 'round',
	}, [
		h('path', { d: 'M19.5 12.572L12 20l-7.5-7.428A5 5 0 1 1 12 6.006a5 5 0 1 1 7.5 6.572' })
	])
});

export {
	ShieldIcon,
	LightningIcon,
	SettingsIcon,
	RadioIcon,
	PuzzleIcon,
	CodeFile,
	CogIcon,
	BracesFile,
	TestTubeIcon,
	ClockIcon,
	ShieldCheckIcon,
	XSocialIcon,
	GithubIcon,
	CopyIcon,
	MessageIcon,
	TerminalIcon,
	CalendarIcon,
	ArrowUpRightIcon,
	LinkedInSocialIcon,
	LinkIcon,
	ChatGptIcon,
	ClaudeIcon,
	MarkdownIcon,
	DiscordIcon,
	HeartIcon
}