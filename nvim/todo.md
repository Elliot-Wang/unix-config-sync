# todo list
- [x] fuzzy finder and preview
    - LeaderF first, telescope, fzf.lua as alternatives.
- [x] remove useless plugin
    - vlime/vlime, for LISP
    - nvim-zh/better-escape.vim
    - Neur1n/neuims - input method switcher, long time(4y) not updated.
    - chrisbra/unicode.vim
    - glacambre/firenvim - condition barely meet, even it is fun
    - copilot - I dont have money!
- [x] remove useless feature
- [x] introduce my config
    - from `.vimrc`, safe and sound!
- [x] colorschema, because of lazy load. colorschema implement not work for not loaded colorschema.
- [x] fix bugs
    - liuchengxu/vista.vim - tags error
    - wilder waring. `:UpdateRemotePlugins` may be useful [Unknown function: _wilder_python_search · Issue #203 · gelguy/wilder.nvim](https://github.com/gelguy/wilder.nvim/issues/203)
    - [x] leaderF jump by `rg` is not correct.
        use telescope to avoid it
    - [ ] python lsp is not perfect
      [用 vim/nvim 写 Python 用什么插件？ - V2EX](https://www.v2ex.com/t/998262)
      [vim/nvim 中是否有能匹敌 pylance 的 Python LSP - V2EX](https://www.v2ex.com/t/916463)

## practice neovim
- gc -> leader+C, **leave it alone**
- lsp config [nvim-cmp](https://github.com/iguanacucumber/magazine.nvim)
  - inline hint, enable it!
    *pyright* not support it, *coc-pyright* is the only option.
  - show document, Why it not work when *cursor hold*.
    *coc-pyright* is better!
  - [x] research **fidget**: *Fidget is an unintrusive window in the corner of your editor that manages its own lifetime.*
      just use `nvim-notify` only
- code action `<leader>+ca` - kosayoda/nvim-lightbulb
  - code action list ***providers*** is various!
- [x] hop.nvim like sneaker, ~*comment it*, config later~ [Commands · smoka7/hop.nvim Wiki](https://github.com/smoka7/hop.nvim/wiki/Commands)
    just help me to jump lines
- organize snippets
  - [ ] ultisnips **problem**
    - trigger key, simple text or regexp
    - expand condition, trigger key or auto trigger
    - conflict with vim-cmp, if vim-cmp missing ultisnips, **it will go wrong**!
- update nvim config at once
  - `<leader>+rc` reload
- surround, still use `surround.vim`
- IDE compiler and run
  - `F9` compile it and run, *AsyncRun*
  - [ ] debuger, [mfussenegger/nvim-dap: Debug Adapter Protocol client implementation for Neovim](https://github.com/mfussenegger/nvim-dap)
- [ ] obsidian repo
  - coc-marksman, with *coc lsp*, it could preview doc(`[[doc-name]]`)
  - obsidian.vim
    - [ ] *config the mappings*
    - [x] create custom Commands selector by telescope
        let's use *FeiyouG/commander.nvim*
    - Useful Commands
      - `:ObsidianTags [TAG ...]` for getting a picker list of all occurrences of the given tags.
      - `:ObsidianFollowLink` `:ObsidianBacklinks`
      - `:ObsidianToday [OFFSET]` to open/create a new daily note.
      - `:ObsidianDailies [OFFSET ...]` to open a picker list of daily notes.
        For example, `:ObsidianDailies -2 1` to list daily notes from 2 days ago until tomorrow.
      - `:ObsidianWorkspace [NAME]` open workspace
- [x] tags (like `#vim`) search for markdown files, it works perfect in Obsidian vault.
- [?] move *qf* windows to new window or even float window.
  - if only I want to read it and keep it for a while,
    otherwise I will close it immediately.
- [x] input method switcher
- [ ] refresh vista, **autocmd**
- [ ] workspace manages
  - `nvim-telescope/telescope-project.nvim`, quick search in project files.
  - what features should be included?

## beatufier
- colorful indent line `"lukas-reineke/indent-blankline.nvim"`
- IMPROVE IT: highlight line is hard to recognized
  - **yazi**, highlight color is to closed to background. Work good with transparent background.
- research it [akinsho/bufferline.nvim: A snazzy bufferline for Neovim](https://github.com/akinsho/bufferline.nvim)
  - enable tabpages
  - enable sidebar seperate
  - enable picking tab use a char
  - hover event
  - custom area, pin tab, groups, lsp indicator, etc.
- minimap [wfxr/minimap.vim: 📡 Blazing fast minimap / scrollbar for vim, powered by code-minimap written in Rust.](https://github.com/wfxr/minimap.vim?tab=readme-ov-file)
- [x] vista colorschema
  - rainbow for every level; use `Toch` at markdown instead.
- [ ] yazi plugin colorschema is bad, highlight is not effect
    change highlight, have no idea.

## debugger
depende on nvim's DAP (Debug Adapter Protocol)
- [ ] debuger, [mfussenegger/nvim-dap: Debug Adapter Protocol client implementation for Neovim](https://github.com/mfussenegger/nvim-dap?tab=readme-ov-file)

A typical debug flow consists of:

> Setting breakpoints via :lua require'dap'.toggle_breakpoint().
> Launching debug sessions and resuming execution via :lua require'dap'.continue().
> Stepping through code via :lua require'dap'.step_over() and :lua require'dap'.step_into().
> Inspecting the state via the built-in REPL: :lua require'dap'.repl.open() or using the widget UI (:help dap-widgets)


