let s:test_directory='test'

let s:test_filename_prefix=''
let s:test_filename_suffix='_test'

let s:test_command_prefix='!python -m test.'
let s:test_command_suffix=''

" change to the test file of the source code, or vice versa
function! TestFile()
  let full_filename=expand("%:t")
  let filename_only=expand("%:t:r")
  let extension=expand("%:e")

  " set alternate file name
  if IsTestFile(full_filename)
    let a_filename = substitute(full_filename, s:test_filename_prefix .'\(.*\)'. s:test_filename_suffix, '\1', '')
    let a_path = getcwd() . '/'
  else
    let a_filename = s:test_filename_prefix . filename_only . s:test_filename_suffix. ".".extension
    let a_path = getcwd() . '/'. s:test_directory .'/'
  endif

  " check if file exists
  let full_a_filepath = a_path . a_filename
  let file_exists = filereadable(full_a_filepath)
  if file_exists
    execute("e " . a_path . a_filename)
  else
    echoerr "Cannot find file: " . full_a_filepath
  end
endfunction

function! RunTest()
  let full_filename=expand("%:t")
  let filename_only=expand("%:t:r")
  let extension=expand("%:e")

  " set test file name
  if IsTestFile(full_filename)
    let test_filename = RemoveExtension(full_filename)
  else
    let test_filename = s:test_filename_prefix . filename_only . s:test_filename_suffix
  endif

  " run test: !python -m test.file_to_test
  let test_command = s:test_command_prefix . test_filename . s:test_command_suffix
  execute test_command
endfunction

" return 1 if given filename is test file, 0 if not
function! IsTestFile(full_filename)
  let s:test_idx = stridx(a:full_filename, s:test_filename_suffix .'.')
  return s:test_idx == -1 ? 0 : 1
endfunction

function! RemoveExtension(filename)
    return substitute(a:filename, '\(.*\)\.[^.]*', '\1', '')
endfunction

"
command! T :call TestFile()
command! TT :call RunTest()

