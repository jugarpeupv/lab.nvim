# 👩‍🔬 lab.nvim

**Heads up:** *lab.nvim is still very early in development and should be considered beta.*

## Goal
- Provide an array of unique **prototyping** tools in neovim. 
- These tools should be extremely configurable and modular in nature.

## Features

### Code Runner
- The foundational feature for lab.nvim is a code runner with real-time, inline feedback. (Inspired by [runjs](https://runjs.app/), [quokka](https://quokkajs.com/) and others.)
- The code runner currently supports javascript with additional language support planned for the near future.

#### Commands

| Command | Action |
:---------| :-------
| `Lab code run` | Run or resume the code runner on the current buffer. |
| `Lab code stop` | Stop the code runner on the current buffer. |
| `Lab code panel` | Show the code runner info buffer |

## Requirements
- neovim >= 0.7.2
- plenary.nvim
- node >= 16.10.0

## Example Setup

```
Plug 'nvim-lua/plenary.nvim'
Plug '0x100101/lab.nvim'

lua require('lab').setup {}

nnoremap <F4> :Lab code stop<CR>
nnoremap <F5> :Lab code run<CR>
nnoremap <F6> :Lab code panel<CR>
```
