#MockAPI link:
#https://6acacfb33115bcc958210ebc.mockapi.io/users

require 'tk'
require 'tkextlib/tile'
require 'httparty'
require 'json'
require 'time'


#Show a message in a text box
def show_output(box, message)
  #unlocks the textbox
  box.configure(state: 'normal')
  box.delete('1.0', 'end')
  box.insert('end', message)
  box.configure(state: 'disabled')
end

#Turn the server response into text with the status code
def format_response(response)
  #receives he hTTParty response code and then saves it
  code = response.code

  #checks what the code is, and then displays a message based on it
  if code == 404
    return "HTTP 404: Not found. Check the API URL or the user ID."
  elsif code >= 500
    return "HTTP #{code}: Server error.\n#{response.body}"
  elsif code >= 400
    return "HTTP #{code}: Request failed.\n#{response.body}"
  end

  #catches errors while parsing the JSON text.
  begin
    data = JSON.parse(response.body)
    "HTTP #{code}: Success\n" + JSON.pretty_generate(data)
  rescue JSON::ParserError
    "HTTP #{code}: Could not read the JSON response."
  end
end

# Send a POST or DELETE request to the API
def api_request(method, url, id = nil, body = nil)
  #removes any whitespace from the URL
  url = url.strip

  #first checks if the URL is empty
  if url.empty?
    return "Error: API URL is empty."
  #checks if the URL starts with the right prefix
  elsif !url.start_with?('http://', 'https://')
    return "API URL error: URL must start with http:// or https://"
  end

  #emoves a "/" at the end if it is there
  url = url.chomp('/')
  url = url + "/" + id if id

  #catching any network errors
  begin
    if method == :post
      response = HTTParty.post(url, body: body.to_json,
                               headers: { 'Content-Type' => 'application/json' },
                               timeout: 10)
    else
      response = HTTParty.delete(url, timeout: 10)
    end
    format_response(response)
  rescue SocketError, Errno::ECONNREFUSED, Timeout::Error
    "Network error: could not reach the server."
  rescue URI::InvalidURIError, HTTParty::Error
    "API URL error: the URL is not valid."
  rescue StandardError => e
    "Error: #{e.message}"
  end
end

#build the post tab
def build_post_tab(notebook, url_var)
  frame = Tk::Tile::Frame.new(notebook, padding: 10)
  notebook.add(frame, text: 'POST')

  #create a container frame for inside the notebook
  first_var = TkVariable.new('')
  last_var = TkVariable.new('')
  email_var = TkVariable.new('')
  phone_var = TkVariable.new('')

  #create 4 Tk variables 
  Tk::Tile::Label.new(frame, text: 'First Name').grid(row: 0, column: 0, sticky: 'w', pady: 4)
  Tk::Tile::Entry.new(frame, textvariable: first_var, width: 35).grid(row: 0, column: 1)

  Tk::Tile::Label.new(frame, text: 'Last Name').grid(row: 1, column: 0, sticky: 'w', pady: 4)
  Tk::Tile::Entry.new(frame, textvariable: last_var, width: 35).grid(row: 1, column: 1)

  Tk::Tile::Label.new(frame, text: 'Email').grid(row: 2, column: 0, sticky: 'w', pady: 4)
  Tk::Tile::Entry.new(frame, textvariable: email_var, width: 35).grid(row: 2, column: 1)

  Tk::Tile::Label.new(frame, text: 'Phone').grid(row: 3, column: 0, sticky: 'w', pady: 4)
  Tk::Tile::Entry.new(frame, textvariable: phone_var, width: 35).grid(row: 3, column: 1)

  #Results box
  output = TkText.new(frame, height: 14, width: 60, state: 'disabled')
  output.grid(row: 5, column: 0, columnspan: 2, pady: 8)

  #defines what happens when the "Create user" button is clicked
  create_click = proc {
    #reads each value from the variable and cuts out any extra space
    first = first_var.value.strip
    last = last_var.value.strip
    email = email_var.value.strip
    phone = phone_var.value.strip

    #Makes sure no field is empty
    if first.empty? || last.empty? || email.empty? || phone.empty?
      show_output(output, "Error: all four fields are required.")
    #if fields aren't empty, check if email format is correct
    elsif !email.include?('@') || !email.include?('.')
      show_output(output, "Error: please enter a valid email.")
    else
      #get the time now and setup the user
      now = Time.now.utc.iso8601
      user = { firstName: first, lastName: last, email: email,
               phone: phone, createdAt: now, updatedAt: now }
      show_output(output, api_request(:post, url_var.value, nil, user))
    end
  }

  #
  Tk::Tile::Button.new(frame, text: 'Create User', command: create_click)
    .grid(row: 4, column: 0, columnspan: 2, pady: 8)
end


#Similar to post tab but for Delete
def build_delete_tab(notebook, url_var)
  frame = Tk::Tile::Frame.new(notebook, padding: 10)
  notebook.add(frame, text: 'DELETE')

  #id variable
  id_var = TkVariable.new('')

  Tk::Tile::Label.new(frame, text: 'User ID').grid(row: 0, column: 0, sticky: 'w', pady: 4)
  Tk::Tile::Entry.new(frame, textvariable: id_var, width: 15).grid(row: 0, column: 1)

  output = TkText.new(frame, height: 14, width: 60, state: 'disabled')
  output.grid(row: 2, column: 0, columnspan: 2, pady: 8)

  #defines what hapens when the delete button is clicked. similar to post button
  delete_click = proc {
    id = id_var.value.strip

    #checks to make sure that id is not less than 1 and is also a digit
    if id !~ /\A\d+\z/ || id.to_i < 1
      show_output(output, "Error: invalid user ID. Enter a positive whole number.")
    else
      answer = Tk.messageBox(type: 'yesno', icon: 'warning', title: 'Confirm Delete',
                             message: "Are you sure you want to delete user #{id}?")
      if answer == 'yes'
        show_output(output, api_request(:delete, url_var.value, id))
      else
        show_output(output, "Delete cancelled.")
      end
    end
  }

  Tk::Tile::Button.new(frame, text: 'Delete User', command: delete_click)
    .grid(row: 1, column: 0, columnspan: 2, pady: 8)
end
