require 'tk'
require 'tkextlib/tile'

require_relative 'get_tab'
require_relative 'instructions_tab'

# Create the application window.
root = TkRoot.new
root.title = 'Project 3 API Client'
root.geometry('1250x750')

# Set the API URL.
url = TkVariable.new(
  'https://6ac5b3a554a61668c5f75b94.mockapi.io/users'
)

row = Tk::Tile::Frame.new(root)
row.pack(fill: 'x', padx: 10, pady: 10)

Tk::Tile::Label.new(
  row, text: 'API URL:'
).pack(side: 'left')

Tk::Tile::Entry.new(
  row,
  textvariable: url,
  width: 85
).pack(side: 'left')

# Create the tabs.
notebook = Tk::Tile::Notebook.new(root)
notebook.pack(fill: 'both', expand: true)

GetTab.new(notebook, url)
InstructionsTab.new(notebook)

# Start the application.
Tk.mainloop

