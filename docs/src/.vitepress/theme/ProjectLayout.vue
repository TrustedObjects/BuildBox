<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
// The figure is a plain SVG file, its single source. Inlining it rather than
// serving it as an image is what lets a page style it: the zones are real DOM
// elements, so the [data-focus] rules of styles/index.css dim all of them but
// the one the page is about, and the palette follows the VitePress theme
// variables with no second rendering for the dark theme.
// @ts-ignore: Vite serves the file as a string
import source from '../../dev/figures/project_layout.svg?raw'

defineProps<{
  // Zone to keep lit: every other one is dimmed. None means the whole figure.
  highlight?: 'project' | 'target' | 'package' | 'tool'
}>()

// v-html parses as HTML, where an XML declaration would land as a stray
// comment node. The file keeps it to stay a valid standalone SVG.
const svg = source.replace(/<\?xml[\s\S]*?\?>/, '')

// medium-zoom gives every image of a page a click to enlarge, but it only
// knows about <img> and this figure is inline SVG. Same gesture, same overlay
// colour, so the two behave alike.
const mounted = ref(false)
const zoomed = ref(false)

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape') close()
}

function open() {
  zoomed.value = true
  window.addEventListener('keydown', onKeydown)
}

function close() {
  zoomed.value = false
  window.removeEventListener('keydown', onKeydown)
}

// The overlay is teleported to the body, to escape the stacking context of the
// page, and only once mounted: there is nothing to teleport to while the page
// is rendered on the server.
onMounted(() => { mounted.value = true })
onUnmounted(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <div
    class="bbx-figure bbx-figure-zoomable"
    :data-focus="highlight"
    role="button"
    tabindex="0"
    aria-label="Enlarge the project organisation figure"
    @click="open"
    @keydown.enter.prevent="open"
    @keydown.space.prevent="open"
    v-html="svg"
  ></div>

  <Teleport v-if="mounted" to="body">
    <Transition name="bbx-zoom">
      <div v-if="zoomed" class="bbx-zoom" @click="close">
        <div class="bbx-figure bbx-zoom-figure" :data-focus="highlight" v-html="svg"></div>
      </div>
    </Transition>
  </Teleport>
</template>
