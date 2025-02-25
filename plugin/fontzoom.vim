" The fontsize controller in gVim.
" Version: 0.2.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

" FIXME: Neovim support assumes you are running on Neovim-qt.
let s:supported = has('nvim') || has('gui_running')
if exists('g:loaded_fontzoom') || !s:supported
  finish
endif
let g:loaded_fontzoom = 1

let s:save_cpo = &cpo
set cpo&vim


function! s:change_fontsize(font, size)
    return join(map(split(a:font, '\\\@<!,'),
    \   printf('substitute(v:val, %s, %s, "g")',
    \   string(g:fontzoom_pattern),
    \   string('\=max([1,' . a:size . '])'))), ',')
endfunction

function! s:set_guifont(font)
  " If it has GUI shim use it
  if has('nvim') && exists("*GuiFont")
    " the second argument is to supress bad metric warning.
    call GuiFont(a:font, 1)
  else
    let &guifont = a:font
  endif
endfunction

function! s:set_guifontwide(font)
  let &guifontwide = a:font
endfunction

function! s:fontzoom(size, reset)
  if a:reset
    if exists('s:keep')  " Reset font size.
      let [guifont, guifontwide, &lines, &columns] = s:keep
      call s:set_guifont(guifont)
      call s:set_guifontwide(guifontwide)
      unlet! s:keep
    endif
  elseif a:size ==# ''
    echo matchstr(&guifont, g:fontzoom_pattern)
  else
    if !exists('s:keep')
      let s:keep = [&guifont, &guifontwide, &lines, &columns]
    endif
    let newsize = (a:size =~# '^[+-]' ? 'submatch(0)' : '') . a:size
    call s:set_guifont(s:change_fontsize(&guifont, newsize))
    call s:set_guifontwide(s:change_fontsize(&guifontwide, newsize))
    " Keep window size if possible.
    let [&lines, &columns] = s:keep[2 :]
  endif
endfunction


if !exists('g:fontzoom_pattern')
  " TODO: X11 is not tested because I do not have the environment.
  let g:fontzoom_pattern =
  \   has('nvim')    || has('win32')   || has('win64') ||
  \   has('mac')     || has('macunix') ? ':h\zs\d\+':
  \   has('gui_gtk') || has('gui_qt')  ? '\s\+\zs\d\+$':
  \   has('X11')                       ? '\v%([^-]*-){6}\zs\d+\ze%(-[^-]*){7}':
  \                                      '*Unknown system*'
endif


" Commands.
command! -narg=? -bang -bar Fontzoom call s:fontzoom(<q-args>, <bang>0)

" Key mappings.
nnoremap <silent> <Plug>(fontzoom-larger)
\                 :<C-u>Fontzoom +<C-r>=v:count1<CR><CR>
nnoremap <silent> <Plug>(fontzoom-smaller)
\                 :<C-u>Fontzoom -<C-r>=v:count1<CR><CR>

if !exists('g:fontzoom_no_default_key_mappings')
\  || !g:fontzoom_no_default_key_mappings
  silent! nmap <unique> <silent> + <Plug>(fontzoom-larger)
  silent! nmap <unique> <silent> - <Plug>(fontzoom-smaller)
  silent! nmap <unique> <silent> <C-ScrollWheelUp> <Plug>(fontzoom-larger)
  silent! nmap <unique> <silent> <C-ScrollWheelDown> <Plug>(fontzoom-smaller)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
