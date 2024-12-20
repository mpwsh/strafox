std = "min+love"
max_line_length = 120
ignore = {
 "612", -- A line contains trailing whitespace.
 "611", -- A line contains only whitespace
 "541", -- Cannot infer type
}
exclude_files = { 
  "moonshine/*"
}
globals = {
  "love",    -- Allow Love2D framework globals
}
