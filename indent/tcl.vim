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
    let ppnum = prevnonblank(pnum-1)
    let ppline = getline(ppnum)

    " Check for continuation line

    " if previous line is continuation line
    if Is_Continuation_Line(pline)
        let ind = ind + &sw
        let braceclass = '[[{]'
        let bracepos = match(pline, braceclass, matchend(pline, '.*[]}]'))
        if ppnum != 0 && bracepos == -1
            " check if previous line is the first line of continuation lines,
            " if is, current line should indent, if not, current line should
            " decrease one shiftwidth
            "
            " if previous is closing a block, should check the line
            " above the opening line
            if pline =~ "[]}]\s*\\$" 
                let match_pair_lnum=Get_Matching_Lnum(pnum)
                let match_pair_pline=getline(prevnonblank(match_pair_lnum-1))
                if Is_Continuation_Line(match_pair_pline)
                    let ind = ind - &sw
                endif
                " if previous line is just a common line, should check its
                " previous line
            elseif Is_Continuation_Line(ppline)

                let ind = ind - &sw
            endif
        endif
        " if previous line is not continuation line but is closing a block
        " check if previous line is last line of continuation lines
        "
        " check the opening line and its previous line
    elseif pline =~ "[]}]\s*$" || pline =~ "[]}]\s*;.*$"
        let match_pair_lnum = Get_Matching_Lnum(pnum)
        let match_pair_pnum = prevnonblank(match_pair_lnum-1)
        let match_pair_pline=getline(match_pair_pnum)
        if Is_Continuation_Line(match_pair_pline)
            let ind = ind - &sw
        endif
        " if previous line is not continuation line
    else 
        " if its previous-previous line is continuation line
        if Is_Continuation_Line(ppline)
            " check if previous line starts a new block which starts with '{' or
            " '['
            let braceclass = '[[{]'
            let bracepos = match(pline, braceclass, matchend(pline, '.*[]}]'))
            if bracepos == -1
                let ind = ind - &sw
            endif
        endif

    endif

    " Set current line indention according to previous line, if previous line
    " is a single closing brace or bracket does not de-indent because itself has de-indented
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

    " Check for single closing brace on current line
    if line =~ '^\s*}'
        let pos = matchend(line, '}')
        call cursor(v:lnum, pos)
        let [match_pair_lnum, match_pair_col] = Find_Matching_Pair()
        let ind = indent(match_pair_lnum)
    endif

    " Check for single closing bracket on current line, a single closing bracket means a backslash in previous line
    if line =~ '^\s*]'
        let pos = matchend(line, ']')
        call cursor(v:lnum, pos)
        let [match_pair_lnum, match_pair_col] = Find_Matching_Pair()
        let ind = indent(match_pair_lnum)
    endif

    return ind
endfunction

function! Get_Matching_Lnum(lnum)
    let line = getline(a:lnum)
    let pos = matchend(line, '.*[]}]')
    call cursor(a:lnum, pos)
    let [match_pair_lnum, match_pair_col] = Find_Matching_Pair()
    return match_pair_lnum
endfunction

function! Is_Continuation_Line(line)
    if a:line =~ '\\$'
        return 1
    else 
        return 0
    endif
endfunction

function! Find_Matching_Pair()
    let c_lnum = line('.')
    let c_col = col('.')
    let before = 0

    let text = getline(c_lnum)
    let matches = matchlist(text, '\(.\)\=\%'.c_col.'c\(.\=\)')
    if empty(matches)
        let [c_before, c] = ['', '']
    else
        let [c_before, c] = matches[1:2]
    endif
    let plist = split(&matchpairs, '.\zs[:,]')
    let i = index(plist, c)

    " Figure out the arguments for searchpairpos().
    if i % 2 == 0
        let s_flags = 'nW'
        let c2 = plist[i + 1]
    else
        let s_flags = 'nbW'
        let c2 = c
        let c = plist[i - 1]
    endif
    if c == '['
        let c = '\['
        let c2 = '\]'
    endif

    let [m_lnum, m_col] = searchpairpos(c, '', c2, s_flags)
    return [m_lnum, m_col]
endfunction

