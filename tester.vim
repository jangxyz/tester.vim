" TODO
"  - show error in quickfix

let s:test_directory='test'

let s:test_filename_prefix=''
let s:test_filename_suffix='_test'

"let s:test_command_prefix='!python test/'
let s:test_command_prefix='!testoob '
let s:test_command_suffix=''

let s:last_line_saves={}

function! s:GenerateTestCommand(test_name, test_suit, test_case)
    if !empty(a:test_suit) && !empty(a:test_case)
        let test_arg = a:test_suit .".". a:test_case     
    else
        let test_arg = a:test_suit . a:test_case
    endif
    return s:test_command_prefix . a:test_name ." ". test_arg . s:test_command_suffix
endfunction

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

function! s:ConvertFullTestFilename2FullFilename(full_filename)
    let path     = fnamemodify(a:full_filename, ":p:h")
    let filename = fnamemodify(a:full_filename, ":p:t")
    return s:ConvertTestPath2Path(path) .'/'. s:ConvertTestFilename2Filename(filename)
endfunction

function! s:ConvertFullFilename2FullTestFilename(full_filename)
    let path     = fnamemodify(a:full_filename, ":p:h")
    let filename = fnamemodify(a:full_filename, ":p:t")
    return s:ConvertPath2TestPath(path) . s:ConvertFilename2TestFilename(filename)
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
function! s:JumpFile()
    let full_filename = expand("%:p")
    let filename=expand("%:p:t")
    let path=expand("%:p:h")

    " set alternate file name and path
    if s:IsTestFile(filename)
        "let a_filename = s:ConvertTestFilename2Filename(filename)
        "let a_path = s:ConvertTestPath2Path(path)
        let full_a_filename = s:ConvertFullTestFilename2FullFilename(full_filename)
    else
        "let a_filename = s:ConvertFilename2TestFilename(filename)
        "let a_path = s:ConvertPath2TestPath(path)
        let full_a_filename = s:ConvertFullFilename2FullTestFilename(full_filename)
    endif

    " check if file exists
    "let full_a_filepath = a_path . a_filename
    if filereadable(full_a_filename)
        call s:SaveCurrentLine()         " save current position
        call s:OpenFile(full_a_filename)
        call s:LoadLastLine()            " load position, if previously saved
    else
        echoerr "Cannot find file: " . full_a_filename
    end
endfunction

"function! s:RunTestCommand(testing_directory, test_name)
function! s:RunTestCommand(test_file, test_suit, test_case)
    "let tempfile = tempname()
    let test_command = s:GenerateTestCommand(a:test_file, a:test_suit, a:test_case)
    "let current_directory=getcwd()
    echo test_command

    "execute 'lcd '. a:testing_directory
    execute test_command
    "execute 'lcd '. current_directory
endfunction

function! s:RunTest()
    let full_filename=expand("%:p")
    let path=expand("%:p:h")

    " set test file name
    let test_name = ''
    let test_case_class    = ''
    let single_test_method = ''
    if s:IsTestFile(full_filename)
        let test_file = full_filename
        "let testing_directory = s:ConvertTestPath2Path(path)
        let test_case_class    = s:IsInTestCaseClass()
        let single_test_method = s:IsInSingleTestMethod()
    else
        let test_file = s:ConvertFullFilename2FullTestFilename(full_filename)
        "let testing_directory = path
    endif

    " run test: !python -m test.file_to_test
    "call s:RunTestCommand(testing_directory, test_name)
    call s:RunTestCommand(test_file, test_case_class, single_test_method)
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

" TODO: 
"   1. cannot find out if it is inside a block comment ''' <> '''
"   2. cannot find out subclass of unittest.TestCase
function! s:IsInTestCaseClass()
    let current_line_num = line('.')
    let line_list = getline(1,current_line_num)
    for line in reverse(line_list)
        if s:IsTestCaseClassLine(line)
            return s:ExtractClassNameFromLine(line)
        elseif s:IsClassLine(line)
            return ""
        endif
    endfor
    return ""
endfunction
function! s:ExtractClassNameFromLine(line)
    let test_case_class_pattern = '^\s*class\s\(\S\+\)(unittest.TestCase):'
    return substitute(a:line, test_case_class_pattern, '\1', "")
endfunction
function! s:IsTestCaseClassLine(line)
    let test_case_class_pattern = '^\s*class\s\(\S\+\)(unittest.TestCase):'
    return match(a:line, test_case_class_pattern) != -1
endfunction
function! s:IsClassLine(line)
    let class_pattern = '^\s*class\s\S\+:'
    return match(a:line, class_pattern) != -1
endfunction

" TODO: 
"   1. cannot find out if it is inside a block comment ''' <> '''
"   2. cannot find out if prefix has changed (!= test)
"   3. cannot find out if argument is other than self
function! s:IsInSingleTestMethod()
    let current_line_num = line('.')
    let line_list = getline(1,current_line_num)
    for line in reverse(line_list)
        if s:IsSingleTestMethodLine(line)
            return s:extractMethodNameFromLine(line)
        elseif s:IsMethodLine(line) || s:IsClassLine(line)
            return ""
        endif
    endfor
    return ""
endfunction
function! s:extractMethodNameFromLine(line)
    let test_method_pattern = '^\s*def \(test\S*\)(self):'
    return substitute(a:line, test_method_pattern, '\1', "")
endfunction
function! s:IsSingleTestMethodLine(line)
    let test_method_pattern = '^\s*def \(test\S*\)(self):'
    return match(a:line, test_method_pattern) != -1
endfunction
function! s:IsMethodLine(line)
    let method_pattern = '^\s*def\s\S\+(\S*):'
    return match(a:line, method_pattern) != -1
endfunction

function! s:SaveCurrentLine()
    let full_filepath=expand("%:p")
    let s:last_line_saves[full_filepath] = winsaveview()
endfunction

function! s:LoadLastLine()
    let full_filepath=expand("%:p")
    if has_key(s:last_line_saves, full_filepath)
        call winrestview(s:last_line_saves[full_filepath])
    endif
endfunction

command! T  :call s:JumpFile()
command! TT :call s:RunTest()


