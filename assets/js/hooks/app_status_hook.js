const AppStatusHook = {
  mounted() {
    console.log("AppStatusHook mounted()")

    // Attach to window so we can easily call it
    window.AppStatusHook = this;
  },

  push_set_visible(visible, target) {
    console.log(`push_set_visible: ${visible} to id: ${target}`)

    this.pushEventTo(target, 'set-visible', {visible: visible})
  }
}

export default AppStatusHook;