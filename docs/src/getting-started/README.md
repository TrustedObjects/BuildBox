# Introduction

BuildBox is an environment designed to develop, build and deliver projects.

It provides a standard way to define and manage projects ressources.
The goal is to simplify environment setup and build process, and to help develpment on embedded / cross-compiled projects.

All projects components and implied tools are versionned and tracked by BuildBox, to guarantee delivery reproductibility in the future.
This is helpful to be able to quickly deliver a new release for an old project, starting from a known state.

As it is running in a container, BuildBox is isolated from developer's host system.
Moreover, projects are using their own environments, to avoid interactions between them.

