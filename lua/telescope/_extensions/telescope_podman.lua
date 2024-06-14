local telescope_podman = require('telescope-podman')

return require('telescope').register_extension({
    exports = {
        show_images = telescope_podman.show_images,
        show_containers = telescope_podman.show_containers,
    },
})
