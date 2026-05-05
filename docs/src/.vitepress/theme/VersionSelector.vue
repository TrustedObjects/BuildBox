<!-- This file is part of BuildBox project -->
<!-- Copyright (C) 2020-2026 Trusted Objects -->

<!-- This program is free software; you can redistribute it and/or -->
<!-- modify it under the terms of the GNU General Public License -->
<!-- version 2, as published by the Free Software Foundation. -->

<!-- This program is distributed in the hope that it will be useful, -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the -->
<!-- GNU General Public License for more details. -->

<!-- You should have received a copy of the GNU General Public License -->
<!-- along with this program; if not, see -->
<!-- <https://www.gnu.org/licenses/>. -->

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useData } from 'vitepress'

const { theme } = useData()
const currentVersion = theme.value.currentVersion as string | undefined
const versions = ref<{ tag: string; path: string }[]>([])

onMounted(async () => {
  try {
    const res = await fetch(window.location.origin + '/versions.json')
    const data = await res.json()
    versions.value = data.versions ?? []
  } catch (_) {}
})

const selectedPath = computed({
  get() {
    // URL is always the ground truth: a non-root prefix match is unambiguous.
    const loc = window.location.pathname
    const byPath = versions.value.find(v => v.path !== '/' && loc.startsWith(v.path))
    if (byPath) return byPath.path
    // At root (or no prefix match): confirm with the baked-in version tag.
    if (currentVersion) {
      const byTag = versions.value.find(v => v.tag === currentVersion)
      if (byTag) return byTag.path
    }
    return versions.value.find(v => v.path === '/') ? '/' : ''
  },
  set(path: string) {
    window.location.href = path
  },
})
</script>

<template>
  <div v-if="versions.length > 1" class="version-selector">
    <select v-model="selectedPath">
      <option v-for="v in versions" :key="v.tag" :value="v.path">
        {{ v.tag }}
      </option>
    </select>
  </div>
</template>

<style scoped>
.version-selector {
  padding: 0 8px;
  display: flex;
  align-items: center;
}

.version-selector select {
  appearance: none;
  font-size: 13px;
  font-weight: 600;
  font-family: inherit;
  padding: 4px 28px 4px 12px;
  border: 1px solid transparent;
  border-radius: 20px;
  background-color: var(--vp-button-brand-bg);
  color: var(--vp-button-brand-text);
  cursor: pointer;
  outline: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M7 10l5 5 5-5z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 8px center;
  transition: background-color 0.25s;
}

.version-selector select:hover {
  background-color: var(--vp-button-brand-hover-bg);
}

.version-selector select option {
  background: var(--vp-c-bg);
  color: var(--vp-c-text-1);
  font-weight: normal;
}
</style>
