<script setup>

</script>

<template>
	<div id="highlights" class="flex flex-col w-full gap-8 flex-col lg:py-16 py-8 2xl:px-64 lg:px-16 px-8">
		<div class="flex gap-8 items-center">
			<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="#FF9800" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m12 17.75l-6.172 3.245l1.179-6.873l-5-4.867l6.9-1l3.086-6.253l3.086 6.253l6.9 1l-5 4.867l1.179 6.873z"/></svg>
			<div class="text-lg text-pretty text-serinus tracking-wide">
				Hightlights
			</div>
		</div>
		<div class="flex flex-col gap-2">
			<div class="text-3xl text-pretty">
				Powerful features for humans
			</div>
			<div class="text-base text-pretty text-gray-600 w-full 2xl:w-[52rem] lg:w-[36rem]">
				Designed to make backend development in Dart easy and enjoyable, avoiding unnecessary complexity for you to focus on your application.
			</div>
		</div>
		<div class="flex gap-4 flex-col lg:flex-row">
			<div class="p-4 flex justify-center items-center border border-gray-200 rounded-lg">
				<div class="flex flex-col gap-4">
					<div class="flex gap-4 items-center">
						<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="#FF9800" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m12 3l8 4.5v9L12 21l-8-4.5v-9zm0 9l8-4.5M12 12v9m0-9L4 7.5"/></svg>
						<div class="text-lg text-pretty tracking-wide text-center font-medium text-serinus">
							Just return
						</div>
					</div>
					<div class="text-sm text-pretty">
						Return whatever you want from your route handlers: Strings, Maps, Lists, Streams, Files, Futures, or custom objects.
					</div>
				</div>
			</div>
			<div class="p-4 flex justify-center items-center border border-gray-200 rounded-lg">
				<div class="flex flex-col gap-4">
					<div class="flex gap-4 items-center">
						<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="#FF9800" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M3 6a2 2 0 1 0 4 0a2 2 0 1 0-4 0m7 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0m7 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0M3 18a2 2 0 1 0 4 0a2 2 0 1 0-4 0m7 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0M5 8v8m7-8v8"/><path d="M19 8v2a2 2 0 0 1-2 2H5"/></g></svg>
						<div class="text-lg text-pretty tracking-wide text-center font-medium text-serinus">
							Specialized tools
						</div>
					</div>
					<div class="text-sm text-pretty">
						Hooks, Exception Filters and Pipes to intercept and transform requests and responses to suit your needs.
					</div>
				</div>
			</div>
			<div class="p-4 flex justify-center items-center border border-gray-200 rounded-lg">
				<div class="flex flex-col gap-4">
					<div class="flex gap-4 items-center">
						<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="#FF9800" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12h4l3 8l4-16l3 8h4"/></svg>
						<div class="text-lg text-pretty tracking-wide text-center font-medium text-serinus">
							Data in real-time
						</div>
					</div>
					<div class="text-sm text-pretty">
						With WebSockets and Server-Sent Events, you can easily build real-time applications that push updates to clients instantly.
					</div>
				</div>
			</div>
			<div class="p-4 flex justify-center items-center border border-gray-200 rounded-lg">
				<div class="flex flex-col gap-4">
					<div class="flex gap-4 items-center">
						<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="none" stroke="#FF9800" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m5.931 6.936l1.275 4.249m5.607 5.609l4.251 1.275m-5.381-5.752l5.759-5.759M4 5.5a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0-3 0m13 0a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0-3 0m0 13a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0-3 0m-13-3a4.5 4.5 0 1 0 9 0a4.5 4.5 0 1 0-9 0"/></svg>
						<div class="text-lg text-pretty tracking-wide text-center font-medium text-serinus">
							Universal Adapters
						</div>
					</div>
					<div class="text-sm text-pretty">
						Build REST APIs, Microservices and more with the same framework, using different adapters to suit your needs.
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<style scoped>
p {
	margin: 0 !important;
}
#highlights > .container {
	grid-template-columns: repeat(4,minmax(0,1fr));
}
.results{
	line-height: 1rem;
}
ol {
	padding: 0;
}
</style>