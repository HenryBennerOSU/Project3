
require 'tk'
require 'tkextlib/tile'
require 'httparty'
require 'json'
require 'uri'
require 'net/http'
require 'time'

# Validate the API URL and user ID.
def validate_update_request(url_var, id)
  url = url_var.value.to_s.strip

  if url.empty?
    return [nil, 'Error: API URL is empty.']
  end

  begin
    uri = URI.parse(url)

    unless uri.is_a?(URI::HTTPS) &&
           uri.host &&
           uri.query.nil? &&
           uri.fragment.nil? &&
           uri.path.match?(%r{/users/?\z})
      return [nil, 'API URL error: enter a valid HTTPS users URL.']
    end
  rescue URI::InvalidURIError
    return [nil, 'API URL error: invalid URL.']
  end

  unless id.to_s.match?(/\A[1-9]\d*\z/)
    return [nil, 'Error: enter a positive numeric User ID.']
  end

  ["#{url.sub(%r{/$}, '')}/#{id}", nil]
end

# Send a PUT or PATCH request and display its HTTP status and JSON.
def send_update_request(method, url, body)
  response =
    if method == :put
      HTTParty.put(
        url,
        headers: { 'Content-Type' => 'application/json' },
        body: body.to_json,
        timeout: 10
      )
    else
      HTTParty.patch(
        url,
        headers: { 'Content-Type' => 'application/json' },
        body: body.to_json,
        timeout: 10
      )
    end

  code = response.code

  begin
    data = JSON.parse(response.body)
    formatted = JSON.pretty_generate(data)
  rescue JSON::ParserError
    formatted = response.body.empty? ? '(Empty response body)' :
      "Invalid JSON response:\n#{response.body}"
  end

  if code == 404
    "HTTP #{code}: User not found.\n#{formatted}"
  elsif code >= 500
    "HTTP #{code}: Server error.\n#{formatted}"
  elsif code >= 400
    "HTTP #{code}: Request failed.\n#{formatted}"
  elsif response.success?
    "HTTP #{code}: Success\n#{formatted}"
  else
    "HTTP #{code}\n#{formatted}"
  end

rescue SocketError, Errno::ECONNREFUSED, Timeout::Error,
       Net::OpenTimeout, Net::ReadTimeout
  'Network error: could not reach the server.'
rescue URI::InvalidURIError
  'API URL error: the URL is not valid.'
rescue HTTParty::Error => e
  "HTTP request error: #{e.message}"
rescue StandardError => e
  "Error: #{e.message}"
end

# Build the PUT and PATCH tabs.
def build_update_tab(notebook, url_var, method)
  is_put = method == :put
  title = is_put ? 'PUT' : 'PATCH'

  frame = Tk::Tile::Frame.new(notebook, padding: 10)
  notebook.add(frame, text: title)

  id_var = TkVariable.new('')
  first_var = TkVariable.new('')
  last_var = TkVariable.new('')
  email_var = TkVariable.new('')
  phone_var = TkVariable.new('')

  fields = [
    ['User ID', id_var],
    ['First Name', first_var],
    ['Last Name', last_var],
    ['Email', email_var],
    ['Phone', phone_var]
  ]

  fields.each_with_index do |(label, variable), row|
    Tk::Tile::Label.new(
      frame, text: label
    ).grid(row: row, column: 0, sticky: 'w', pady: 4)

    Tk::Tile::Entry.new(
      frame, textvariable: variable, width: 35
    ).grid(row: row, column: 1, sticky: 'w', pady: 4)
  end

  help_text = if is_put
    'PUT replaces all four editable fields. Fill in every field.'
  else
    'PATCH changes only fields that are not blank.'
  end

  Tk::Tile::Label.new(
    frame, text: help_text
  ).grid(row: 5, column: 0, columnspan: 2, sticky: 'w', pady: 6)

  output = TkText.new(
    frame, height: 14, width: 70, state: 'disabled'
  )
  output.grid(row: 7, column: 0, columnspan: 2, pady: 10)

  update_click = proc do
    id = id_var.value.to_s.strip
    url, error = validate_update_request(url_var, id)

    if error
      show_output(output, error)
      next
    end

    first = first_var.value.to_s.strip
    last = last_var.value.to_s.strip
    email = email_var.value.to_s.strip
    phone = phone_var.value.to_s.strip

    if is_put
      if [first, last, email, phone].any?(&:empty?)
        show_output(output, 'Error: PUT requires all four fields.')
        next
      end

      unless email.include?('@') && email.include?('.')
        show_output(output, 'Error: enter a valid email.')
        next
      end

      body = {
        firstName: first,
        lastName: last,
        email: email,
        phone: phone
      }
    else
      body = {}
      body[:firstName] = first unless first.empty?
      body[:lastName] = last unless last.empty?
      body[:email] = email unless email.empty?
      body[:phone] = phone unless phone.empty?

      if body.empty?
        show_output(output, 'Error: enter at least one field to update.')
        next
      end

      if body.key?(:email) &&
         !(email.include?('@') && email.include?('.'))
        show_output(output, 'Error: enter a valid email.')
        next
      end
    end

    show_output(output, send_update_request(method, url, body))
  end

  button_text = is_put ? 'PUT / Replace User' : 'PATCH User'

  Tk::Tile::Button.new(
    frame, text: button_text, command: update_click
  ).grid(row: 6, column: 0, columnspan: 2, pady: 8)
end

def build_put_tab(notebook, url_var)
  build_update_tab(notebook, url_var, :put)
end

def build_patch_tab(notebook, url_var)
  build_update_tab(notebook, url_var, :patch)
end

