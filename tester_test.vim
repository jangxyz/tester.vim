so tester.vim

" XXX: not easy enough
let s:script_id = "47"
function! s:DecorateFunctionName(func_name)
    let new_prefix = "<SNR>".s:script_id."_"
    return substitute(a:func_name, "^s:", new_prefix, "")
endfunction

function! s:CallFunctionName(func_str)
    let decorated_function_str = s:DecorateFunctionName(a:func_str)
    let result = eval(decorated_function_str)
    return result
endfunction

" -----------------------------------------------------------------------------

UTSuite "[tester] command"

function! s:TestCommand_T_calls_s:TestFile()
    " 2 for full match
    Assert exists(":T") == 2 
endfunction


" -----------------------------------------------------------------------------

UTSuite "[tester] decorating filename into test"

function! s:TestSplittingFilenameIntoNameAndExtension()
    let filename = "somefile.ext"
    Assert <SNR>47_SplitFilename(filename) == ['somefile', 'ext']
endfunction

function! s:TestConvertFilenameIntoTestFilename()
    let filename = "somefile.ext"
    Assert <SNR>47_ConvertFilename2TestFilename(filename) == "somefile_test.ext"
endfunction

function! s:TestConvertFilenameIntoTestFilenameEvenItAlreadyHasTest()
    let filename = "somefile_test.ext"
    Assert <SNR>47_ConvertFilename2TestFilename(filename) == "somefile_test_test.ext"
endfunction

function! s:TestTestFilenameIntoFilename()
    let filename = "somefile_test.ext"
    Assert <SNR>47_ConvertTestFilename2Filename(filename) == "somefile.ext"
endfunction


UTSuite "[tester] changing path to test path and vice versa"

function! s:TestConvertPathIntoTestPath()
    let path='/some/path/'
    Assert <SNR>47_ConvertPath2TestPath(path) == "/some/path/test/"
endfunction

function! s:TestConvertPathIntoTestPathRemovesDuplicateSlashes()
    let path='/some/path//'
    Assert <SNR>47_ConvertPath2TestPath(path) == "/some/path/test/"
endfunction

function! s:TestConvertPathIntoTestPathConvertsToAbsPathIfRelative()
    " let's say you are currently at /some/path
    let cwd=substitute(getcwd(), '/$', '', "")

    let path=''
    echo <SNR>47_ConvertPath2TestPath(path)
    Assert <SNR>47_ConvertPath2TestPath(path) == cwd ."/test/"
endfunction


function! s:TestConvertTestPathIntoPathRemoves_test_AtEnd()
    let path='/some/path/test'
    Assert <SNR>47_ConvertTestPath2Path(path) == "/some/path/"
endfunction

function! s:TestConvertTestPathIntoPathWorksRegardlessOfSlashAtEnd()
    let path='/some/path/test/'
    Assert <SNR>47_ConvertTestPath2Path(path) == "/some/path/"
endfunction

function! s:TestConvertTestPathIntoPathOnlyRemovesFinal_test()
    let path='/some/path/test/final/test/'
    Assert <SNR>47_ConvertTestPath2Path(path) == "/some/path/test/final/"
endfunction

function! s:TestConvertTestPathIntoPathCanReadSimplifyPath()
    let path='/some/path/test/dir/..'
    Assert <SNR>47_ConvertTestPath2Path(path) == "/some/path/"
endfunction

function! s:TestConvertTestPathIntoPathCanApplyRelativePath()
    let path='relative/path'
endfunction

" -----------------------------------------------------------------------------

UTSuite "[tester] internal#HasWordTest"

function! s:TestReturn_1_IfHasWordTest()
    let with_test = 'somecode_test.vim'
    Assert <SNR>47_HasWordTest(with_test) == 1
endfunction
 
function! s:TestReturn_0_IfDoNotHaveWordTest()
    let without_test = 'somecode.vim'
    Assert <SNR>47_HasWordTest(without_test) == 0
endfunction

function! s:TestHavingAWordTestIgnoringCase()
    let with_test_ic = 'somecode_tEsT.vim'
    Assert <SNR>47_HasWordTest(with_test_ic) == 1
endfunction

function! s:TestIsTestFile()
    let with_test = 'somecode_test.vim'
    Assert <SNR>47_IsTestFile(with_test) == 1
endfunction



