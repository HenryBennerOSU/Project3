require 'tk'
require 'tkextlib/tile'

class InstructionsTab

  # Create the Instructions tab.
  def initialize(notebook)
    frame = Tk::Tile::Frame.new(notebook)
    notebook.add(frame, text: 'Instructions')

    instructions = <<~TEXT
      PROJECT 3 INSTRUCTIONS

      Start:
      Enter your MockAPI users URL at the top of the application.

      GET:
      Click Refresh to load all users.
      Search finds users containing matching text.
      Filter displays users matching the selected field.
      Sort changes the order of the user list.
      Enter a User ID and click Get One User to see one user.

      POST:
      Enter first name, last name, email, and phone.
      Click Create User to add the new user.

      PUT:
      Enter the User ID and all replacement field values.
      Click Replace User to replace the user's information.

      PATCH:
      Enter a User ID and only the fields you want to change.
      Leave the other fields blank.
      Click PATCH User to save your changes.

      DELETE:
      Enter the User ID of the user to remove.
      Click Delete User and confirm the deletion.

      HTTP STATUS CODES:
      200 = Success
      201 = Created
      404 = Not found
      500 = Server error

      ERROR HANDLING:
      Check the URL, network connection, and User ID
      when errors occur.

      Refresh the GET tab after creating,
      updating, or deleting a user.
    TEXT

    Tk::Tile::Label.new(
      frame,
      text: 'How to Use the API Client'
    ).pack(pady: 10)

    text = TkText.new(
      frame,
      width: 85,
      height: 28,
      wrap: 'word'
    )

    text.insert('end', instructions)
    text.configure(state: 'disabled')

    text.pack(
      fill: 'both',
      expand: true,
      padx: 10,
      pady: 10
    )
  end
end

