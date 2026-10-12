require "tk"
require "tkextlib/tile"
require "httparty"
require"json"
require_relative "post_and_delete"
require_relative "instructions_tab"
require_relative "get_tab"
require_relative "put_patch"

#set up main application
url_var = TkVariable.new("https://6ac5b3a554a61668c5f75b94.mockapi.io/users")
root = TkRoot.new
notebook = Tk::Tile::Notebook.new(root) 

#set up all tabs
instructions = InstructionsTab.new(notebook)
get_tab = GetTab.new(notebook, url_var)
post_tab = build_post_tab notebook, url_var
delete_tab = build_delete_tab notebook, url_var
put_tab = build_put_tab(notebook, url_var)
patch_tab = build_patch_tab(notebook, url_var)

notebook.pack fill: 'both', expand: true

Tk.mainloop
