so tester.vim

" XXX: not easy enough
let s:script_id = "54"
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

function! s:TestHasFunctionDecorateFilename()
    Assert exists("*".s:DecorateFunctionName("s:DecorateFilename")) != 0
endfunction

function! s:TestSplittingFilenameIntoNameAndExtension()
    let filename = "somefile.ext"
    Assert <SNR>54_SplitFilename(filename) == ['somefile', 'ext']
endfunction

function! s:TestConvertFilenameIntoTestFilename()
    let filename = "somefile.ext"
    Assert <SNR>54_ConvertFilename2TestFilename(filename) == "somefile_test.ext"
endfunction

function! s:TestConvertFilenameIntoTestFilenameEvenItAlreadyHasTest()
    let filename = "somefile_test.ext"
    Assert <SNR>54_ConvertFilename2TestFilename(filename) == "somefile_test_test.ext"
endfunction

function! s:TestTestFilenameIntoFilename()
    let filename = "somefile_test.ext"
    Assert <SNR>54_ConvertTestFilename2Filename(filename) == "somefile.ext"
endfunction


" -----------------------------------------------------------------------------

UTSuite "[tester] internal#HasWordTest"

function! s:TestReturn_1_IfHasWordTest()
    let with_test = 'somecode_test.vim'
    Assert <SNR>54_HasWordTest(with_test) == 1
endfunction
 
function! s:TestReturn_0_IfDoNotHaveWordTest()
    let without_test = 'somecode.vim'
    Assert <SNR>54_HasWordTest(without_test) == 0
endfunction

function! s:TestHavingAWordTestIgnoringCase()
    let with_test_ic = 'somecode_tEsT.vim'
    Assert <SNR>54_HasWordTest(with_test_ic) == 1
endfunction

function! s:TestIsTestFile()
    let with_test = 'somecode_test.vim'
    Assert <SNR>54_IsTestFile(with_test) == 1
endfunction

UTSuite "[tester] internal#IsTestFile"


