
" add.py -> test/add_test.py
let s:test_directory='test'
let s:test_filename_prefix=''
let s:test_filename_suffix='_test'

" add.py -> test_add.py
"let s:test_directory=''
"let s:test_filename_prefix='test_'
"let s:test_filename_suffix=''

let s:test_command='unittest'
"let s:test_command='testoob'

let s:default_alltests_py = "python -c \"import unittest, sys, os, re; sys.path.append(os.curdir); t_py_re = re.compile('^t(est)?_.*\.py$'); is_test = lambda filename: t_py_re.match(filename); drop_dot_py = lambda filename: filename[:-3]; modules_to_test = [drop_dot_py(module) for module in filter(is_test, os.listdir(os.curdir))]; print 'Testing', ', '.join(modules_to_test); alltests = unittest.TestSuite(); [alltests.addTest(unittest.findTestCases(module)) for module in map(__import__, modules_to_test)]; call_alltests = lambda: alltests; unittest.main(defaultTest='call_alltests')\""

let s:last_line_saves={}

function! s:GenerateTestCommand(test_file, test_case, test_method)
    let function_name = s:test_command == "testoob" ? "s:BuildTestOOBCommand" : "s:BuildTestCommand"
    return function(function_name)(a:test_file, a:test_case, a:test_method)
endfunction
"
function! s:BuildTestCommand(test_file, test_case, test_method)
    let test_module = s:RemoveExtension(a:test_file)

    let first_arg  = "'". test_module ."'"
    let second_arg = empty(a:test_method) ? a:test_case : a:test_case .".". a:test_method
    let arg_tuple  = empty(second_arg) ? first_arg : first_arg .", '". second_arg ."'"

    let cmd = "python -c \"import unittest; unittest.main(". arg_tuple .")\""

    return cmd
endfunction

function! s:BuildTestOOBCommand(test_file, test_case, test_method)
    let cmd = "testoob ". a:test_file
    if !empty(a:test_case)
        let cmd = cmd ." ". a:test_case
        let cmd = empty(a:test_method) ? cmd : cmd .".". a:test_method 
    endif

    return cmd
endfunction

" change from source code to test code or vice versa
function! s:JumpFile()
    let full_filename = s:GetFullFilename()

    " set alternate file name and path
    if s:IsTestFile(full_filename)
        let full_a_filename = s:ConvertFullTestFilename2FullFilename(full_filename)
    else
        let full_a_filename = s:ConvertFullFilename2FullTestFilename(full_filename)
    endif

    " check if file exists
    if filereadable(full_a_filename)
        call s:SaveCurrentLine()         " save current position
        call s:OpenFile(full_a_filename)
        call s:LoadLastLine()            " load position, if previously saved
    else
        echoerr "Cannot find file: " . full_a_filename
    end
endfunction

function! s:ExecuteMake(bang)
    execute 'make'.(a:bang ? '!' : '')
endfunction

function! s:ExecuteCommandByMakeprg(command, bang)
    let previous_makeprg = s:SetLocal('makeprg', a:command)
    "echo getcwd() ."$ ". &makeprg
    call s:ExecuteMake(a:bang)
    call s:SetLocal('makeprg', previous_makeprg)
endfunction

function! s:RunTestCommand(test_file, test_case, test_method, bang)
    let test_directory = s:ExtractPath(a:test_file)
    let previous_directory = s:ChangeDirectoryTo(test_directory)
    let test_command = s:GenerateTestCommand(a:test_file, a:test_case, a:test_method)
    call s:ExecuteCommandByMakeprg(test_command, a:bang)
    call s:ChangeDirectoryTo(previous_directory)
endfunction

" run appropriate test
function! s:RunTest(bang)
    let full_filename = s:GetFullFilename()

    if s:IsTestFile(full_filename)
        let test_file = full_filename
        let test_case_class    = s:IsInTestCaseClass()
        let single_test_method = s:IsInSingleTestMethod()

        call s:RunTestCommand(test_file, test_case_class, single_test_method, a:bang)
    else
        echo full_filename
        let test_file = s:ConvertFullFilename2FullTestFilename(full_filename)
        echo test_file
        call s:RunTestCommand(test_file, '', '', a:bang)
    endif
endfunction

" run all tests
function! s:RunAllTests(bang)
    let full_filename = s:GetFullFilename()
    let test_directory = s:ExtractPath(full_filename)
    if s:IsTestFile(full_filename) 
        let test_directory = s:ConvertTestPath2Path(s:ExtractPath(full_filename))
    endif
    let previous_directory = s:ChangeDirectoryTo(test_directory)

    "let run_default_all_tests = 0
    " if user has some makeprg
    let makeprg_value = &makeprg
    if makeprg_value != "make"
        "let cmd = 'python '. s:default_alltests_script_name
        "call s:ExecuteCommandByMakeprg(cmd, a:bang)
        call s:ExecuteMake(a:bang)

    " if user doesn't have specific makeprg
    else
        call s:ExecuteCommandByMakeprg(s:default_alltests_py, a:bang)
    endif
    
    call s:ChangeDirectoryTo(previous_directory)
endfunction

" return 1 if given filename is test file, 0 if not
function! s:IsTestFile(full_filename)
    let filename = fnamemodify(a:full_filename, ":t")
    return s:HasWordTest(filename)
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

function! s:SetLocal(option_name, value)
    let previous_value = eval('&'. a:option_name)
    let escaped_value  = escape(a:value, ' "')
    execute 'setlocal '. a:option_name .'='. escaped_value
    return previous_value
endfunction

function! s:SaveCurrentLine()
    let full_filepath = s:GetFullFilename()
    let s:last_line_saves[full_filepath] = winsaveview()
endfunction

function! s:LoadLastLine()
    let full_filepath = s:GetFullFilename()
    if has_key(s:last_line_saves, full_filepath)
        call winrestview(s:last_line_saves[full_filepath])
    endif
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
    return substitute(simplify(a:path), s:test_directory.'/\?$', '', "")
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

" returns 1 if given string has 'test', ignoring case
" returns 0 if not
function! s:HasWordTest(filename)
    let filename_no_ext   = fnamemodify(a:filename, ":r")
    let test_file_pattern = '\c^'.s:test_filename_prefix.'.*'.s:test_filename_suffix.'$'
    let matched_index = match(filename_no_ext, test_file_pattern)
    if matched_index != -1
        return 1 
    else
        return 0
    endif
endfunction



""
"" Utility functions
""

"
" Files and Paths
"

" open a file
function! s:OpenFile(filepath)
    execute("e " . a:filepath)
endfunction

function! s:ChangeDirectoryTo(directory)
    let current_directory = s:GetPath()
    exec 'lcd '. a:directory
    return current_directory
endfunction

" /full/path/filename.ext
function! s:GetFullFilename()
    return expand("%:p")
endfunction

function! s:GetPath()
    return expand("%:p:h")
endfunction

function! s:ExtractPath(full_filename)
    return fnamemodify(a:full_filename, ":p:h")
endfunction

" return list of name and extension
function! s:SplitFilename(filename)
    let pattern = '\(.*\)\.\([^.]*\)'
    let name = substitute(a:filename, pattern, '\1', "")
    let ext  = substitute(a:filename, pattern, '\2', "")
    return [name, ext]
endfunction

function! s:RemoveExtension(filename)
    return fnamemodify(a:filename, ":r")
endfunction



command! T  :call s:JumpFile()
command! -bang TT :call s:RunTest(<bang>0)
command! -bang TA :call s:RunAllTests(<bang>0)

