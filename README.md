##telescope-podman.nvim

**telescope-podman** is a in-progress plugin to integrateOCI engines with telescope allowing the user to interact
with the desired engine. As it is still in-progress it only works with podman hence the name and has a very basic
functionality (`show_images`, `show_containers`) and start/stop containers by pressing the `RETURN` key while in telescope.

## Installation

#### lazy.nvim

```lua
{
	'JersonCortes/telescope-podman',
	event = 'VeryLazy',
	dependencies = {
		'nvim-telescope/telescope.nvim',
	},
	config = function()
		require('telescope').load_extension('telescope_podman')
	end,

	--Keybinds
	keys = {
		{
			'<Leader>ci',
            ':Telescope telescope_podman show_images',
		},
		{
			'<Leader>cp',
			':Telescope telescope_podman show_containers',
		},
	},
}
```
