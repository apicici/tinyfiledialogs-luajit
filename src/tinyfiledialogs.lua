local ffi = require 'ffi'
local ext =  jit.os == "Windows" and ".dll" or jit.os == "OSX" and ".dylib" or ".so"
local flag, global = pcall(require, 'global')
local libs_dir = flag and global.libs_dir or '.'
local C = ffi.load(libs_dir .. '/' .. 'libtinyfiledialogs' .. ext)

ffi.cdef[[

char const * tinyfd_saveFileDialog(
    char const * const aTitle ,
    char const * const aDefaultPathAndFile ,
    int const aNumOfFilterPatterns ,
    char const * const * const aFilterPatterns ,
    char const * const aSingleFilterDescription ) ;     

char const * tinyfd_openFileDialog(
    char const * const aTitle ,
    char const * const aDefaultPathAndFile ,
    int const aNumOfFilterPatterns ,
    char const * const * const aFilterPatterns ,
    char const * const aSingleFilterDescription ,
    int const aAllowMultipleSelects ) ;         

char const * tinyfd_selectFolderDialog(
    char const * const aTitle ,
    char const * const aDefaultPath ) ;     

char const * tinyfd_colorChooser(
    char const * const aTitle ,
    char const * const aDefaultHexRGB ,
    unsigned char const aDefaultRGB[3] ,
    unsigned char aoResultRGB[3] ) ;
]]

local tfd = {}

function tfd.saveFileDialog(title, default_path_and_file, filter_patterns, single_filter_description)
    filter_patterns = filter_patterns or {}
    num_filter_patterns = #filter_patterns
    filter_patterns = filter_patterns and ffi.new("char const*[" .. tostring(num_filter_patterns) .. "]", filter_patterns)
    local result = C.tinyfd_saveFileDialog(title, default_path_and_file, num_filter_patterns, filter_patterns, single_filter_description)
    return result ~= nil and ffi.string(result) or ""
end

function tfd.openFileDialog(title, default_path_and_file, filter_patterns, single_filter_description, allow_multiple_selects)
    allow_multiple_selects = allow_multiple_selects or false
    filter_patterns = filter_patterns or {}
    num_filter_patterns = #filter_patterns
    filter_patterns = filter_patterns and ffi.new("char const*[" .. tostring(num_filter_patterns) .. "]", filter_patterns)
    local result = C.tinyfd_openFileDialog(title, default_path_and_file, num_filter_patterns, filter_patterns, single_filter_description, allow_multiple_selects)
    if result == nil then return {} end
    
    local str =  ffi.string(result)
    local t = {}
    if allow_multiple_selects then
        for s in str:gmatch("([^|]+)") do
            t[#t + 1] = s
        end
    else
        t[1] = str
    end
    return t
end

function tfd.selectFolderDialog(title, default_path)
    local result = C.tinyfd_selectFolderDialog(title, default_path)
    return result ~= nil and ffi.string(result) or nil
end

function tfd.colorChooser(title, default_color)
    default_color = default_color or '#FF0000'
    local hex, rgb
    if type(default_color) == 'string' then
        hex = default_color
    elseif type(default_color) == 'table' then
        rgb = ffi.new("unsigned char const [3]", default_color)
    end
    orgb = ffi.new("unsigned char [3]")
    local result = C.tinyfd_colorChooser(title, hex, rgb, orgb)
    if result == nil then return end    
    return ffi.string(result), {orgb[1], orgb[2], orgb[3]}
end


return tfd
