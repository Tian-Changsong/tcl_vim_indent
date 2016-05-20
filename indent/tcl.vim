"  vim: set sw=4 sts=4:
"  Maintainer	: Changsong Tian (tian1988320@126.com)
"  Revised on	: 2016-05-19 23:29:29
"  Language	: Tcl/tk

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif

"let b:did_indent = 1

setlocal indentexpr=GetTclIndent()
setlocal indentkeys-=:,0#
setlocal indentkeys+=0]

" Only define the function once.
if exists("*GetTclIndent")
    finish
endif

function GetTclIndent()
    " Find a non-blank line above the current line.
    let pnum = prevnonblank(v:lnum - 1)
    " Hit the start of the file, use zero indent.
    if pnum == 0
        return 0
    endif
    let line = getline(v:lnum)
    let pline = getline(pnum)

    let ind = indent(pnum)

    " Check for continuation line
    if pline =~ '\\$'
        let ind = ind + &sw
        " If previous line is backslashed and its previous is also backslashed,
        " current line should not indent again, so de-indent due to previous
        " indention
        let ppnum = prevnonblank(pnum - 1)
        if ppnum != 0
            let ppline = getline(ppnum)
            if ppline =~'\\$'
                let ind = ind - &sw
            endif
        endif
    endif

    " Check for single closing brace on current line
    if line =~ '^\s*}'
        let ind	= ind - &sw
    endif

    " Check for single closing bracket on current line, a single closing bracket means a backslash in previous line
    if line =~ '^\s*]'
        let ind	= ind - &sw
    endif

    " Set current line indention according to previous line, if previous line
    " is a single closing brace or bracket does not de-indent because itself has de-indented
    if pline !~ '^\s*}\s*$' && pline !~ '^\s*]\s*$' && pline !~ '\\$'
        let braceclass = '[][{}]'
        let bracepos = match(pline, braceclass, matchend(pline, '^\s*[]}]'))
        while bracepos != -1
            let brace = strpart(pline, bracepos, 1)
            if brace == '{' || brace == '['
                " each '{' causes indent, '[' does not
                let ind = ind + &sw
            else
                " each ']' and '}' causes de-indent
                let ind = ind - &sw
            endif
            let bracepos = match(pline, braceclass, bracepos + 1)
        endwhile
    endif

    return ind
endfunction
