
require 'tk'
require 'tkextlib/tile'
require 'httparty'
require 'json'
require 'uri'

class GetTab
  FIELDS = %w[id firstName lastName email phone createdAt updatedAt]

  def initialize(notebook, api_url)
    @api_url = api_url
    @users = []

    @frame = Tk::Tile::Frame.new(notebook)
    notebook.add(@frame, text: 'GET')

    build_buttons
    build_table
    build_result
  end

  # Create search, filter, and sort controls.
  def build_buttons
    top = Tk::Tile::Frame.new(@frame)
    top.pack(fill: 'x', padx: 10, pady: 5)

    Tk::Tile::Label.new(top, text: 'Search:').pack(side: 'left')

    @search = TkVariable.new

    Tk::Tile::Entry.new(
      top, textvariable: @search, width: 16
    ).pack(side: 'left')

    Tk::Tile::Button.new(
      top, text: 'Search',
      command: proc { show_users }
    ).pack(side: 'left')

    Tk::Tile::Button.new(
      top, text: 'Refresh',
      command: proc { get_all }
    ).pack(side: 'left')

    Tk::Tile::Label.new(top, text: 'Filter:').pack(side: 'left')

    @filter_field = TkVariable.new
    @filter_field.value = 'firstName'

    Tk::Tile::Combobox.new(
      top,
      textvariable: @filter_field,
      values: FIELDS,
      state: 'readonly',
      width: 12
    ).pack(side: 'left')

    @filter_text = TkVariable.new

    Tk::Tile::Entry.new(
      top, textvariable: @filter_text, width: 14
    ).pack(side: 'left')

    Tk::Tile::Button.new(
      top, text: 'Apply',
      command: proc { show_users }
    ).pack(side: 'left')

    bottom = Tk::Tile::Frame.new(@frame)
    bottom.pack(fill: 'x', padx: 10, pady: 5)

    Tk::Tile::Label.new(bottom, text: 'Sort:').pack(side: 'left')

    @sort_field = TkVariable.new
    @sort_field.value = 'id'

    Tk::Tile::Combobox.new(
      bottom,
      textvariable: @sort_field,
      values: FIELDS,
      state: 'readonly',
      width: 14
    ).pack(side: 'left')

    @direction = TkVariable.new
    @direction.value = 'Ascending'

    Tk::Tile::Combobox.new(
      bottom,
      textvariable: @direction,
      values: ['Ascending', 'Descending'],
      state: 'readonly',
      width: 14
    ).pack(side: 'left')

    Tk::Tile::Button.new(
      bottom, text: 'Sort',
      command: proc { show_users }
    ).pack(side: 'left')

    Tk::Tile::Button.new(
      bottom, text: 'Clear',
      command: proc {
        @search.value = ''
        @filter_text.value = ''
        @sort_field.value = 'id'
        @direction.value = 'Ascending'
        show_users
      }
    ).pack(side: 'left')
  end

  # Create the user table.
  def build_table
    area = Tk::Tile::Frame.new(@frame)
    area.pack(fill: 'both', expand: true, padx: 10)

    @table = Tk::Tile::Treeview.new(
      area,
      columns: FIELDS,
      show: 'headings',
      height: 12
    )

    names = [
      'ID', 'First Name', 'Last Name',
      'Email', 'Phone', 'Created At', 'Updated At'
    ]

    # Set column headings and widths.
    FIELDS.each_with_index do |field, index|
      @table.heading_configure(field, text: names[index])
      @table.column_configure(
        field,
        width: field == 'email' ? 190 : 130
      )
    end

    @table.pack(fill: 'both', expand: true)
  end

  # Create the user ID and response area.
  def build_result
    row = Tk::Tile::Frame.new(@frame)
    row.pack(fill: 'x', padx: 10, pady: 5)

    Tk::Tile::Label.new(
      row, text: 'User ID:'
    ).pack(side: 'left')

    @user_id = TkVariable.new

    Tk::Tile::Entry.new(
      row, textvariable: @user_id, width: 12
    ).pack(side: 'left')

    Tk::Tile::Button.new(
      row, text: 'Get One User',
      command: proc { get_one }
    ).pack(side: 'left')

    @status = TkVariable.new
    @status.value = 'HTTP Status: No request yet'

    Tk::Tile::Label.new(
      row, textvariable: @status
    ).pack(side: 'left', padx: 15)

    Tk::Tile::Label.new(
      @frame, text: 'JSON Response:'
    ).pack(anchor: 'w', padx: 10)

    @output = TkText.new(
      @frame, height: 9, width: 95
    )

    @output.pack(fill: 'both', padx: 10, pady: 5)
  end

  # Check the API URL.
  def valid_url
    url = @api_url.value.to_s.strip

    if url.empty?
      show_error('Enter an API URL.')
      return nil
    end

    begin
      address = URI.parse(url)

      unless address.is_a?(URI::HTTPS) &&
             address.host &&
             address.query.nil? &&
             address.fragment.nil? &&
             address.path.match?(%r{/users/?\z})
        show_error('Enter a valid HTTPS users API URL.')
        return nil
      end

    rescue URI::InvalidURIError
      show_error('Invalid API URL.')
      return nil
    end

    url.sub(%r{/$}, '')
  end

  # Get all users.
  def get_all
    url = valid_url
    return unless url

    request(url, Array) do |data|
      @users = data
      show_users
    end
  end

  # Get one user by ID.
  def get_one
    id = @user_id.value.to_s.strip

    unless id.match?(/\A[1-9][0-9]*\z/)
      show_error('Enter a positive numeric User ID.')
      return
    end

    url = valid_url
    return unless url

    request("#{url}/#{id}", Hash)
  end

  # Send a GET request.
  def request(url, expected_type)
    response = HTTParty.get(url, timeout: 10)

    @status.value = "HTTP Status: #{response.code}"

    unless response.success?
      if response.code == 404
        show_error("User not found.\n#{response.body}")
      elsif response.code >= 500
        show_error("Server error.\n#{response.body}")
      else
        show_error("API request failed.\n#{response.body}")
      end
      return
    end

    data = JSON.parse(response.body)

    unless data.is_a?(expected_type)
      show_error('Unexpected JSON response.')
      return
    end

    show_json(data)
    yield(data) if block_given?

  rescue JSON::ParserError
    show_error('Invalid JSON response.')

  rescue StandardError => e
    show_error("Network error: #{e.message}")
  end

  # Search, filter, sort, and display users.
  def show_users
    rows = @users.dup
    query = @search.value.to_s.downcase.strip

    # Search all user fields.
    unless query.empty?
      rows = rows.select do |user|
        FIELDS.any? do |field|
          user[field].to_s.downcase.include?(query)
        end
      end
    end

    # Filter by a selected field.
    filter = @filter_text.value.to_s.downcase.strip

    unless filter.empty?
      rows = rows.select do |user|
        user[@filter_field.value.to_s].to_s.downcase.include?(filter)
      end
    end

    # Sort the user list.
    field = @sort_field.value.to_s

    rows = rows.sort_by do |user|
      if field == 'id'
        user[field].to_i
      else
        user[field].to_s.downcase
      end
    end

    if @direction.value.to_s == 'Descending'
      rows.reverse!
    end

    # Clear existing table rows.
    @table.children('').each do |item|
      @table.delete(item)
    end

    # Display matching users.
    rows.each do |user|
      values = FIELDS.map do |field_name|
        user[field_name].to_s
      end

      @table.insert('', 'end', values: values)
    end
  end

  # Display JSON data.
  def show_json(data)
    @output.delete('1.0', 'end')
    @output.insert('end', JSON.pretty_generate(data))
  end

  # Display error messages.
  def show_error(message)
    @output.delete('1.0', 'end')
    @output.insert('end', message)
  end
end

