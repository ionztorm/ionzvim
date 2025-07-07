return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		event = { "BufReadPost" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"Saghen/blink.cmp",
		},
		config = function()
			ionzvim.lsp.load_language_configs()
			local mason = require("mason")
			local lspconfig = require("lspconfig")
			local masonlspcfg = require("mason-lspconfig")

			-- local blink_cmp = require("blink.cmp")
			local lsps = ionzvim.lsp.get_server_names()
			local formatters = ionzvim.formatters.get_formatter_names()
			local linters = ionzvim.linters.get_linter_names()
			local ensure_installed = ionzvim.utilities.combine_tables(formatters, linters)

			mason.setup({
				-- ensure_installed = ensure_installed,
				ui = {
					border = "rounded",
				},
			})
			masonlspcfg.setup({
				automatic_installation = true,
				ensure_installed = lsps,
				-- stop auto loading default configs causing duplicate lsp loads, one with default config.
				automatic_enable = false,
			})
			-- local capabilities = blink_cmp.get_lsp_capabilities()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities =
				vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))
			-- capabilities = vim.tbl_deep_extend("force", capabilities, blink_cmp.get_lsp_capabilities())

			local keymaps = require("config.settings.keymaps").lsp
			local on_attach = function(_, bufnr)
				keymaps(bufnr)
			end

			ionzvim.utilities.mason_ensure_installed(ensure_installed)

			local lsp_configs = ionzvim.lsp.configs

			for server, config in pairs(lsp_configs) do
				local lsp_setup = vim.tbl_deep_extend("force", {
					autostart = config.autostart,
					cmd = config.cmd,
					capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {}),
					filetypes = config.filetypes,
					on_attach = on_attach,
					root_dir = config.root_dir,
				}, config)

				lspconfig[server].setup(lsp_setup)
			end
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConfosmInfo" },
		opts = {
			notify_on_error = false,
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
			default_format_opts = {
				async = true,
				timeout_ms = 500,
				lsp_format = "fallback",
			},
			formatters = ionzvim.formatters.get_formatter_configs(),
			formatters_by_ft = ionzvim.formatters.formatters,
		},
	},
	{
		"mfussenegger/nvim-lint",
		event = {
			"BufReadPre",
			"BufNewFile",
		},
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				ionzvim.linters.linters,
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})

			vim.keymap.set("n", "<leader>l", function()
				lint.try_lint()
			end, { desc = "Trigger linting for current file" })
		end,
	},
}
