-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd.packadd('packer.nvim')

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.3',
	  -- or                            , branch = '0.1.x',
	  requires = { {'nvim-lua/plenary.nvim'} }
  }

  use({
	  'rose-pine/neovim',
	  as = 'rose-pine',
	  config = function()
		  vim.cmd('colorscheme rose-pine')
	  end
  })

  use({
      "folke/trouble.nvim",
      config = function()
          require("trouble").setup {
              icons = false,
              -- your configuration comes here
              -- or leave it empty to use the default settings
              -- refer to the configuration section below
          }
      end
  })
  use('ThePrimeagen/vim-be-good')
  
  use {
			'nvim-treesitter/nvim-treesitter',
			run = function()
				local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
				ts_update()
			end,}
  use("nvim-treesitter/playground")
  use("theprimeagen/harpoon")
  use("theprimeagen/refactoring.nvim")
  use("mbbill/undotree")
  use("tpope/vim-fugitive")
  use("nvim-treesitter/nvim-treesitter-context");
  use('mfussenegger/nvim-jdtls')
  use ({
      'nvimdev/lspsaga.nvim',
      after = 'nvim-lspconfig',
      requires = {
        {'nvim-tree/nvim-web-devicons'},  -- Optional, for file icons
        {'nvim-treesitter/nvim-treesitter'}  -- Optional, for better syntax highlighting
      },
      config = function()
          require('lspsaga').setup({})
      end,
  })
  use {
  'VonHeikemen/lsp-zero.nvim',
	  branch = 'v1.x',
	  requires = {
		  -- LSP Support
		  {'neovim/nvim-lspconfig'},
		  {'williamboman/mason.nvim'},
		  {'williamboman/mason-lspconfig.nvim'},

		  -- Autocompletion
		  {'hrsh7th/nvim-cmp'},
		  {'hrsh7th/cmp-buffer'},
		  {'hrsh7th/cmp-path'},
		  {'saadparwaiz1/cmp_luasnip'},
		  {'hrsh7th/cmp-nvim-lsp'},
		  {'hrsh7th/cmp-nvim-lua'},

		  -- Snippets
		  {'L3MON4D3/LuaSnip'},
		  {'rafamadriz/friendly-snippets'},
	  }
  }

  use("folke/zen-mode.nvim")
  use("github/copilot.vim")
  use("eandrju/cellular-automaton.nvim")
  use("laytan/cloak.nvim")
  -- install without yarn or npm
  use({
     "iamcco/markdown-preview.nvim",
     run = function() vim.fn["mkdp#util#install"]() end,
  })

  -- These optional plugins should be loaded directly because of a bug in Packer lazy loading
  use ("nvim-tree/nvim-web-devicons") -- OPTIONAL: for file icons
  use ("lewis6991/gitsigns.nvim") -- OPTIONAL: for git status
  use("romgrk/barbar.nvim")
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true }
  }
  use("EdenEast/nightfox.nvim") 
 -- -- Copilot Chat
 -- use {
 --   'CopilotC-Nvim/CopilotChat.nvim',
 --   branch = "canary",
 --   requires = {
 --     { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
 --     { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
 --   },
 --   opts = {
 --     debug = true, -- Enable debugging
 --     -- See Configuration section for rest
 --   },
 -- }
end)
