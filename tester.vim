" TODO
"  - show error in quickfix

let s:test_directory='test'

let s:test_filename_prefix=''
let s:test_filename_suffix='_test'

let s:test_command_prefix='!python -m test.'
let s:test_command_suffix=''

let s:last_line_saves={}

" change to the test file of the source code, or vice versa
function! s:TestFile()
    let full_filename=expand("%:t")
    "let full_path=getcwd().'/'. expand("%:h")
    let path=expand("%:h")
    if empty(path)
        let path='.'
    endif
    let filename_only=expand("%:t:r")
    let extension=expand("%:e")

    " set alternate file name
    if s:IsTestFile(full_filename)
        let a_filename = substitute(full_filename, s:test_filename_prefix .'\(.*\)'. s:test_filename_suffix, '\1', '')
        "let a_path = getcwd().'/'
        let a_path = path.'/../'
    else
        let a_filename = s:test_filename_prefix . filename_only . s:test_filename_suffix. ".".extension
    "let a_path = full_path.'/'. s:test_directory .'/'
        let a_path = path.'/'. s:test_directory .'/'
    endif
    echo a_path
    echo a_filename

    " check if file exists
    let full_a_filepath = a_path . a_filename
    let file_exists = filereadable(full_a_filepath)
    if file_exists
        call s:SaveCurrentLine()
        execute("e " . a_path . a_filename)
        call s:LoadLastLine()
    else
        echoerr "Cannot find file: " . full_a_filepath
    end
endfunction

function! s:RunTest()
    let full_filename=expand("%:t")
    let filename_only=expand("%:t:r")
    let extension=expand("%:e")
    let path=expand("%:h")

    " set test file name
    let current_directory=getcwd()
    if s:IsTestFile(full_filename)
        let test_filename = s:RemoveExtension(full_filename)
        let testing_directory = path .'/../'
    else
        let test_filename = s:test_filename_prefix . filename_only . s:test_filename_suffix
        let testing_directory = path .'/'
    endif

    " run test: !python -m test.file_to_test
    "echo testing_directory
    let tempfile = tempname()
    let test_command = s:test_command_prefix . test_filename . s:test_command_suffix
    execute 'lcd ' .testing_directory
    execute test_command
    execute 'lcd ' .current_directory
endfunction

" return 1 if given filename is test file, 0 if not
function! s:IsTestFile(full_filename)
    let s:test_idx = stridx(a:full_filename, s:test_filename_suffix .'.')
    return s:test_idx == -1 ? 0 : 1
endfunction

function! s:RemoveExtension(filename)
    return substitute(a:filename, '\(.*\)\.[^.]*', '\1', '')
endfunction

function! s:SaveCurrentLine()
    let full_filepath=expand("%")
    let s:last_line_saves[full_filepath] = winsaveview()
endfunction

function! s:SaveCurrentLine()
    let s:last_line_saves[expand("%")] = winsaveview()
endfunction

function! s:LoadLastLine()
    if has_key(s:last_line_saves, expand("%"))
        call winrestview(s:last_line_saves[expand("%")])
    endif
endfunction

command! T :call s:TestFile()
command! TT :call s:RunTest()

