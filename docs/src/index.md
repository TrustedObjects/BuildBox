---
layout: home
hero:
  name: BuildBox
  image:
    src: /buildbox.png
    alt: BuildBox
  actions:
    - theme: brand
      text: Getting started →
      link: /getting-started/
    - theme: alt
      text: Cheat sheet (PDF)
      link: /cheatsheet.pdf
features:
  - title: Reproducible build
    details: All your project components and all involved tools required to build the deliverable are version constrained, so that the same deliverable can still be rebuilt years later
  - title: Unified process
    details: Whatever the project, the setup and build process is the same. Newcomers learn it once, and a build machine needs no project specific knowledge
  - title: Isolated build environment
    details: BuildBox runs in a container to avoid changes in developer's host system, and lets projects with conflicting toolchains live side by side
  - title: CRA compliance
    details: A target lists every component of a delivery, pinned to an exact revision, which is most of a SBOM. The SBOM tools turn it into SPDX and CycloneDX documents
---

<!--@include: ./parts/news.md-->
