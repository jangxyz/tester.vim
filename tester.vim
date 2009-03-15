" TODO
"  - show error in quickfix

let s:test_directory='test'

let s:test_filename_prefix=''
let s:test_filename_suffix='_test'

let s:test_command_prefix='!python -m test.'
let s:test_command_suffix=''

let s:last_line_saves={}

" ./somefile.ext => ./somefile_test.ext
function! s:ConvertFilename2TestFilename(filename)
    let [name, ext] = s:SplitFilename(a:filename)
    return s:test_filename_prefix .name. s:test_filename_suffix. ".".ext
endfunction

" ./somefile_test.ext => ./somefile.ext
function! s:ConvertTestFilename2Filename(filename)
    return substitute(a:filename, s:test_filename_prefix .'\(.*\)'. s:test_filename_suffix, '\1', '')
endfunction


" add test directory to path
" ./somepath/ => ./somepath/test/
function! s:ConvertPath2TestPath(path)
    " relative path
    let path = fnamemodify(a:path, ":p")

    let result = path.'/'. s:test_directory .'/'
    let duplication_removed = substitute(result, '//\+', '/', "")
    return duplication_removed
endfunction

" strip test at the end if exist
" ./somepath/test/ => ./somepath
function! s:ConvertTestPath2Path(path)
    return substitute(simplify(a:path), 'test/\?$', '', "")
endfunction




" return list of name and extension
function! s:SplitFilename(filename)
    let pattern = '\(.*\)\.\([^.]*\)'
    let name = substitute(a:filename, pattern, '\1', "")
    let ext  = substitute(a:filename, pattern, '\2', "")
    return [name, ext]
endfunction


function! s:OpenFile(filepath)
    execute("e " . a:filepath)
endfunction


" change to the test file of the source code, or vice versa
function! s:TestFile()
    let full_filename=expand("%:t")
    "let full_path=getcwd().'/'. expand("%:h")
    let path=expand("%:p:h")
    if empty(path)
        let path='.'
    endif

    " set alternate file name and path
    if s:IsTestFile(full_filename)
        let a_filename = s:ConvertTestFilename2Filename(full_filename)
        let a_path = s:ConvertTestPath2Path(path)
    else
        let a_filename = s:ConvertFilename2TestFilename(full_filename)
        let a_path = s:ConvertPath2TestPath(path)
    endif

    " check if file exists
    let full_a_filepath = a_path . a_filename
    if filereadable(full_a_filepath)
        call s:SaveCurrentLine()         " save current position
        call s:OpenFile(full_a_filepath)
        call s:LoadLastLine()            " load position, if previously saved
    else
        echoerr "Cannot find file: " . full_a_filepath
    end
endfunction

function! s:GenerateTestCommand(test_name)
    return s:test_command_prefix . a:test_name . s:test_command_suffix
endfunction

function! s:RunTestCommand(testing_directory, test_name)
    let tempfile = tempname()
    let test_command = s:GenerateTestCommand(a:test_name)
    let current_directory=getcwd()

    execute 'lcd '. a:testing_directory
    execute test_command .' &> '. tempfile
    execute 'lcd '. current_directory
endfunction

function! s:RunTest()
    let full_filename=expand("%:t")
    let path=expand("%:p:h")

    " set test file name
    if s:IsTestFile(full_filename)
        let test_name = s:RemoveExtension(full_filename)
        let testing_directory = s:ConvertTestPath2Path(path)
    else
        let test_name = s:RemoveExtension(s:ConvertFilename2TestFilename(full_filename))
        let testing_directory = path
    endif

    " run test: !python -m test.file_to_test
    call s:RunTestCommand(testing_directory, test_name)
endfunction

" returns 1 if given string has 'test', ignoring case
" returns 0 if not
function! s:HasWordTest(filename)
    let matched_index = match(a:filename, '\ctest')
    return matched_index != -1
endfunction

" return 1 if given filename is test file, 0 if not
function! s:IsTestFile(filename)
    return s:HasWordTest(a:filename)
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

