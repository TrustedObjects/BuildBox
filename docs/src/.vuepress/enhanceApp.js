/**
 * Client app enhancement file.
 *
 * https://v1.vuepress.vuejs.org/guide/basic-config.html#app-level-enhancements
 */

export default ({ Vue }) => {
  Vue.mixin({
    mounted () {
      const footer = document.querySelector('.home .footer')
      if (footer && footer.textContent.includes('Trusted Objects')) {
        footer.innerHTML = '© <a href="https://trusted-objects.com" target="_blank" rel="noopener noreferrer">Trusted Objects</a>'
      }
    }
  })
}
