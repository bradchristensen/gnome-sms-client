using Gtk;
using Notify;
using WebKit;
using Soup;

public class MainWindow : Window {

	private PreferencesWindow prefs_window;
	private bool prefs_window_open = false;
	
	public Preferences preferences;

	private Box message_pane;
	private ScrolledWindow messages_scroll;
	private Box message_box;
	private Box container_box;
	private Box web_box;
	private Paned content_box;
	private Button send_button;
	private Label loading_text_label;
	private ToolItem spinner_tool_item;
	private Spinner spinner;
	private TreeView contacts;
	private ListStore listmodel;
	private WebView web_view;
	private Label message_length_label;
	private Entry phone_number_entry;
	private Label label_contact;
	private TextView new_message_entry;
	private Toolbar notification_bar;
	
	private Gee.ArrayList<Contact> contact_list;
	private Gee.ArrayList<Contact> downloaded_list;
	
	private Contact selected_contact;
	private Contact no_contact;
	
	private bool shift_held = false;
	
	private bool downloading_contacts = false;
	
	public MainWindow () {
		this.title = "GNOME SMS Intercepter";
		this.window_position = WindowPosition.CENTER;
		this.set_default_size (600, 400);

		Gdk.Geometry hints = Gdk.Geometry() {
			min_width = 400,
			min_height = 300
		};
		this.set_geometry_hints (this, hints, Gdk.WindowHints.MIN_SIZE);
		
		this.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
		
		this.icon_name = "phone";
	
		var toolbar = new Toolbar ();
		toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
		
		preferences = new Preferences ();
		
		var preferences_button = new ToolButton.from_stock (Stock.PREFERENCES);
		preferences_button.is_important = true;
		preferences_button.set_label ("Preferences");
		preferences_button.clicked.connect ( () => {
			if (prefs_window_open == false) {
				prefs_window_open = true;
				prefs_window = new PreferencesWindow (preferences);
				prefs_window.set_transient_for (this);
				prefs_window.destroy.connect ( () => {
					prefs_window_open = false;
				});
				prefs_window.show_all ();
			} else {
				prefs_window.present ();
			}
		});
		toolbar.add (preferences_button);
		
		var new_button = new ToolButton.from_stock (Stock.NEW);
		new_button.is_important = true;
		new_button.set_label ("New SMS");
		toolbar.add (new_button);

		var sync_button = new ToolButton.from_stock (Stock.REFRESH);
		sync_button.is_important = true;
		sync_button.set_label ("Sync Contacts");
		sync_button.clicked.connect ( () => {
			if (!downloading_contacts) {
				download_contacts ();
			}
		});
		toolbar.add (sync_button);

		var loading_text = new ToolItem ();
		loading_text_label = new Label ("");
		loading_text.add (loading_text_label);
		loading_text_label.set_ellipsize (Pango.EllipsizeMode.END);
		loading_text.halign = Align.END;
		loading_text.set_expand (true);
		loading_text.margin_right = 10;
		toolbar.add (loading_text);
	
		spinner_tool_item = new ToolItem ();
		spinner = new Spinner ();
		//spinner_tool_item.add (spinner);
		spinner.halign = Align.END;
		spinner.margin_right = 10;
		toolbar.add (spinner_tool_item);

		phone_number_entry = new Entry ();
		phone_number_entry.margin = 10;
		phone_number_entry.margin_bottom = 0;
		Border border = Border () {
			top = 5,
			bottom = 5,
			left = 5,
			right = 5
		};
		phone_number_entry.set_inner_border (border);
		var pango_context = this.create_pango_context ();
		var font_desc = pango_context.get_font_description ();
		font_desc.set_size ((int)Math.ceil (font_desc.get_size () * 1.25));
		// 14 * Pango.SCALE
		phone_number_entry.modify_font (font_desc);
		
		label_contact = new Label ("Contact");
		label_contact.modify_font (font_desc);
		label_contact.margin = 10;
		label_contact.margin_left = 13;
		label_contact.margin_bottom = 0;
		label_contact.halign = Align.START;
		label_contact.set_ellipsize (Pango.EllipsizeMode.END);

		new_message_entry = new TextView ();
		new_message_entry.editable = true;
		new_message_entry.set_wrap_mode (WrapMode.WORD_CHAR);
		new_message_entry.left_margin = 5;
		new_message_entry.right_margin = 5;
		new_message_entry.pixels_above_lines = 3;
		new_message_entry.pixels_below_lines = 3;
		new_message_entry.set_accepts_tab (false);
		var new_message_scroll = new ScrolledWindow (null, null);
		new_message_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		new_message_scroll.set_min_content_height (80);
		new_message_scroll.add (new_message_entry);
		new_message_scroll.set_shadow_type (ShadowType.IN);

		message_length_label = new Label ("160/1");

		send_button = new Button ();
		send_button.set_label ("Send");
		send_button.set_focus_on_click (false);
		send_button.clicked.connect (() => {
			send_message (new_message_entry.get_buffer ().text);
			new_message_entry.set_buffer (new TextBuffer (new TextTagTable ()));
		});
		send_button.set_can_default (true);
		send_button.width_request = 80;
		
		new_message_entry.key_press_event.connect ( (e) => {
			stdout.printf ("Key pressed: %d\n", (int)e.keyval);
			string message_text = new_message_entry.get_buffer ().text;
			message_length_label.set_label (message_text.length.to_string () + "/" + message_text.length.to_string ());
			if (e.keyval == 65505) {
				shift_held = true;
			}
			if ((e.keyval == 65293 || e.keyval == 65421) && !shift_held) {
				send_button.activate ();
				return true;
			}
			return false;
		});
		new_message_entry.key_release_event.connect ( (e) => {
			if (e.keyval == 65505) {
				shift_held = false;
			}
			return false;
		});
		new_message_entry.focus_in_event.connect ( (e) => {
			shift_held = false;
			return false;
		});
		
		var send_button_vbox = new Box (Orientation.VERTICAL, 10);
		send_button_vbox.pack_start (send_button, true, true, 0);
		send_button_vbox.pack_start (message_length_label, false, true, 0);

		var new_message_hbox_wrapped = new Box (Orientation.HORIZONTAL, 10);
		new_message_hbox_wrapped.pack_start (new_message_scroll, true, true, 0);
		new_message_hbox_wrapped.pack_start (send_button_vbox, false, false, 0);
		var new_message_hbox = new Box (Orientation.HORIZONTAL, 0);
		new_message_hbox.pack_start (new_message_hbox_wrapped, true, true, 10);

		messages_scroll = new ScrolledWindow (null, null);
		messages_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		message_box = new Box (Orientation.VERTICAL, 10);
		message_box.halign = Align.START;
		message_box.margin_left = 10;
		message_box.margin_right = 10;
		messages_scroll.add_with_viewport (message_box);

		contacts = new TreeView ();
		var contacts_scroll = new ScrolledWindow (null, null);
		contacts_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		contacts_scroll.set_min_content_width (150);
		contacts_scroll.add (contacts);

		listmodel = new ListStore (1, typeof (string));
		contacts.set_model (listmodel);
		contacts.set_headers_visible (false);
		contacts.insert_column_with_attributes (-1, "Name",
			new CellRendererText (), "text", 0);
			
		message_pane = new Box (Orientation.VERTICAL, 0);
		message_pane.pack_start (phone_number_entry, false, false, 0);
		message_pane.pack_start (new_message_hbox, false, false, 10);
		message_pane.pack_start (messages_scroll, true, true, 0);

		content_box = new Paned (Orientation.HORIZONTAL);
		content_box.pack1 (contacts_scroll, false, false);
		content_box.pack2 (message_pane, true, true);

		container_box = new Box (Orientation.VERTICAL, 0);
		//vbox.pack_start (menubar, false, true, 0);
		container_box.pack_start (toolbar, false, true, 0);
		container_box.pack_start (content_box, true, true, 0);

		add (container_box);
		
		contacts.cursor_changed.connect ( () => {
			selected_contact.Draft_Message = new_message_entry.get_buffer ().text;
			var selection = contacts.get_selection ();
			unowned TreeModel model;
			TreeIter iter;
			selection.get_selected (out model, out iter);
			if (model.get_path (iter) != null){
				int index = int.parse (model.get_string_from_iter (iter));
				if (selected_contact != contact_list.get (index)) {
					selected_contact = contact_list.get (index);
					stdout.printf ("Selection changed to %s:", selected_contact.Name);
					foreach (string phone_number in selected_contact.Phone_Numbers) {
						stdout.printf (" %s", phone_number);
					}
					stdout.printf ("\n");
					switch_message_box (selected_contact);
					this.show_all ();
				}
			}
		});
		
		no_contact = new Contact ("", "Phone Number", new Gee.ArrayList<string> ());
		selected_contact = no_contact;
		switch_message_box (selected_contact);
		
		this.show_all ();
		
		try {
			var srv = new SocketService ();
			srv.add_inet_port (3333, null);
			srv.incoming.connect (on_incoming_connection);
			srv.start ();
		} catch (Error e) {
			stderr.printf (e.message);
		}
		
		preferences.load ();
		contact_list = preferences.load_contact_list ();
		refresh_contact_list ();
		loading_text_label.set_text ("Contact list loaded from file.");
	}

	bool on_incoming_connection (SocketConnection conn) {
		stdout.printf ("Got incoming connection\n");
		// Process the request asynchronously
		process_request.begin (conn);
		return true;
	}

	async void process_request (SocketConnection conn) {
		try {
			var dis = new DataInputStream (conn.input_stream);
			//var dos = new DataOutputStream (conn.output_stream);
			string req = yield dis.read_line_async (Priority.HIGH_IDLE);
			//dos.put_string ("Got: %s\n".printf (req));
			stdout.printf ("Got: %s\n".printf (req));

			var parser = new Json.Parser ();
			parser.load_from_data (req, -1);
			var root_object = parser.get_root ().get_object ();
			var phone_number = root_object.get_string_member ("phone_number");
			var message = root_object.get_string_member ("message");
			var timestamp = root_object.get_int_member ("timestamp");
			Markup.escape_text (message);
			
			Contact sender = null;
			foreach (Contact c in contact_list) {
				if (c.Phone_Number == phone_number) {
					sender = c;
					c.receive_message (phone_number, timestamp, message);
				}
			}
			if (sender == null) {
				Gee.ArrayList<string> phone_numbers = new Gee.ArrayList<string> ();
				phone_numbers.add (phone_number);
				Contact unknown_contact = new Contact (phone_number, phone_number, phone_numbers);
				unknown_contact.receive_message (phone_number, timestamp, message);
				sender = unknown_contact;
				contact_list.add (unknown_contact);
				
				TreeIter iter;
				listmodel.append (out iter);
				listmodel.set (iter, 0, unknown_contact.Name);
				this.show_all ();
			}
			
			switch_message_box (selected_contact);
			
			if (notification_bar != null) {
				container_box.remove (notification_bar);
			}
			
			notification_bar = new Toolbar ();
			notification_bar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
			notification_bar.set_icon_size (IconSize.SMALL_TOOLBAR);
			
			var notification_toolitem = new ToolItem ();
			notification_toolitem.set_expand (true);
			var notification_label = new Label ("<b>" + sender.Name + "</b>: " + message);
			notification_label.use_markup = true;
			notification_label.set_ellipsize (Pango.EllipsizeMode.END);
			notification_label.justify = Justification.CENTER;
			var notification_button = new Button ();
			notification_button.add (notification_label);
			notification_button.clicked.connect ( () => {
				container_box.remove (notification_bar);
				selected_contact = sender;
				switch_message_box (selected_contact);
			});
			notification_toolitem.add (notification_button);
			notification_bar.add (notification_toolitem);
			
			container_box.pack_end (notification_bar, false, true, 0);
			
			this.show_all ();
			var notify = new Notification (sender.Name, message, "info");
			notify.show ();
		} catch (Error e) {
			stderr.printf ("Server process error: %s\n", e.message);
		}
	}

	private void send_message (string message) {
		//Time now1 = Time();
		//now1 = Time.local( time_t() );
		//now1.format ("%F %H:%M:%S")
		
		var time = new DateTime.now_local ();
		selected_contact.send_message (time.to_unix (), message);

		/*var myLabel = new Label ("<b>You (" + now1.format ("%F %H:%M:%S") +
			"):</b>\n" + message);
		myLabel.use_markup = true;
		myLabel.halign = Align.FILL;
		myLabel.justify = Justification.LEFT;
		myLabel.wrap = true;
		myLabel.wrap_mode = Pango.WrapMode.WORD_CHAR;
		this.selected_contact.Message_Box.pack_start (myLabel, false, true, 0);
		this.selected_contact.Message_Box.reorder_child (myLabel, 0);
		this.show_all();*/
		switch_message_box (selected_contact);
	}

	private void download_contacts () {
		downloading_contacts = true;
		if (preferences.refresh_token == null) {
			loading_text_label.set_text ("Authentication is required with Google.");
			spinner_tool_item.remove (spinner);
			
			this.web_view = new WebView ();
			this.container_box.remove (this.content_box);
			this.container_box.remove (this.web_box);
			this.web_box = new Box (Orientation.HORIZONTAL, 10);
			var scrolled_window = new ScrolledWindow (null, null);
			scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
			scrolled_window.add_with_viewport (this.web_view);
			web_box.pack_start (scrolled_window, true, true, 0);
			container_box.pack_start (this.web_box, true, true, 0);
			this.show_all ();
			this.web_view.open ("https://accounts.google.com/o/oauth2/auth?scope=https://www.google.com/m8/feeds&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=763353794495.apps.googleusercontent.com");
			this.web_view.title_changed.connect ((source, frame, title) => {
				//this.title = title;
				if (title.contains ("Success code=")) {
					this.container_box.remove (this.web_box);
					this.container_box.pack_start (this.content_box, true, true, 0);
			
					loading_text_label.set_text ("Authenticating with Google...");
					spinner_tool_item.add (spinner);
					spinner.start ();
					this.show_all ();
					
					string success_code = title.substring (13, title.length - 13);
						
					RpcRequest rpc = RpcRequest.get_instance ();
					rpc.add_parameter ("code", success_code);
					rpc.add_parameter ("client_id", "763353794495.apps.googleusercontent.com");
					rpc.add_parameter ("client_secret", "r3cg_S00rEBJ_bNEVNL5dCge");
					rpc.add_parameter ("redirect_uri", "urn:ietf:wg:oauth:2.0:oob");
					rpc.add_parameter ("grant_type", "authorization_code");
					string json_response = rpc.send ("POST", "https://accounts.google.com/o/oauth2/token");
	
					try {
						loading_text_label.set_text ("Downloading contacts from Google...");
		
						var parser = new Json.Parser ();
						parser.load_from_data (json_response, -1);
						var root_object = parser.get_root ().get_object ();
						preferences.access_token = root_object.get_string_member ("access_token");
						preferences.refresh_token = root_object.get_string_member ("refresh_token");
						preferences.save_refresh_token ();
					} catch (Error e) {
						loading_text_label.set_text ("Failed to authenticate with Google.");
						spinner_tool_item.remove (spinner);
						preferences.refresh_token = null;
						download_contacts ();
					}
					
					download_contacts_init ();
				}
			});
		} else {
			loading_text_label.set_text ("Connecting to Google...");
			spinner_tool_item.add (spinner);
			spinner.start ();
			this.show_all ();
		
			try {
				Thread.create<void*> ( () => {
					RpcRequest rpc = RpcRequest.get_instance ();
					rpc.add_parameter ("client_id", "763353794495.apps.googleusercontent.com");
					rpc.add_parameter ("client_secret", "r3cg_S00rEBJ_bNEVNL5dCge");
					rpc.add_parameter ("refresh_token", preferences.refresh_token);
					rpc.add_parameter ("grant_type", "refresh_token");
					string json_response = rpc.send ("POST", "https://accounts.google.com/o/oauth2/token");
		
					loading_text_label.set_text ("Downloading contacts from Google...");
					
					try {
						var parser = new Json.Parser ();
						parser.load_from_data (json_response, -1);
						var root_object = parser.get_root ().get_object ();
						if (root_object.has_member ("error")) {
							preferences.access_token = null;
							preferences.refresh_token = null;
						} else {
							preferences.access_token = root_object.get_string_member ("access_token");
						}
					} catch (Error e) {
						loading_text_label.set_text ("Failed to authenticate with Google.");
						spinner_tool_item.remove (spinner);
						preferences.refresh_token = null;
					}
					
					Idle.add ( () => {
						download_contacts_init ();
						return false;
					});
					return null;
				}, false);
			} catch (ThreadError et) {
				stderr.printf ("Thread error: %s\n", et.message);
			}
		}
	}
	
	private void download_contacts_init () {
		if (preferences.access_token != null) {
			try {
				Thread.create<void*> ( () => {
					downloaded_list = new Gee.ArrayList<Contact> ();
					string url = "https://www.google.com/m8/feeds/contacts/default/full?alt=json&access_token=" + preferences.access_token;
					string data = Utils.soup_get_json (url);
					add_contacts_from_json (data);
					contact_list = downloaded_list;
					Idle.add ( () => {
						refresh_contact_list ();
						preferences.save_contact_list (contact_list);
						loading_text_label.set_text ("Contact list up to date.");
						spinner_tool_item.remove (spinner);
						return false;
					});
					return null;
				}, false);
			} catch (ThreadError e) {
				stderr.printf ("%s\n", e.message);
			}
		} else {
			download_contacts ();
		}
	}
	
	private void add_contacts_from_json (string json) {
		var parser = new Json.Parser ();
		try {
			parser.load_from_data (json, -1);
		} catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
			preferences.refresh_token = null;
			Idle.add ( () => {
				download_contacts ();
				return false;
			});
		}
		var root = parser.get_root ().get_object ().get_object_member ("feed");
		var entry_object = root.get_array_member ("entry");
		foreach (var node in entry_object.get_elements ()) {
			var node_object = node.get_object ();
			string contact_id = node_object.get_object_member ("id").get_string_member ("$t");
			string contact_name = node_object.get_object_member ("title").get_string_member ("$t");
			Gee.ArrayList<string> phone_numbers = new Gee.ArrayList<string> ();
			if (node_object.has_member ("gd$phoneNumber")) {
				foreach (var ph_node in node_object.get_array_member ("gd$phoneNumber").get_elements ()) {
					var ph_object = ph_node.get_object ();
					phone_numbers.add (ph_object.get_string_member ("$t"));
				}
			}
			if (phone_numbers.size > 0) {
				stdout.printf ("%s: ", contact_name);
				foreach (string ph_number in phone_numbers) {
					stdout.printf ("%s, ", ph_number);
				}
				stdout.printf ("\n");
				downloaded_list.add (new Contact(contact_id, contact_name, phone_numbers));
			}
		}
		var link_object = root.get_array_member ("link");
		foreach (var node in link_object.get_elements ()) {
			var node_object = node.get_object ();
			if (node_object.get_string_member ("rel") == "next") {
				string url = node_object.get_string_member ("href") + "&access_token=" + preferences.access_token;
				string data = Utils.soup_get_json (url);
				add_contacts_from_json (data);
			}
		}
	}
	
	private void refresh_contact_list () {
		listmodel.clear ();
		if (contact_list.size  > 0) {
			contact_list.sort((a,b) => {
				return ((Contact)a).Name.ascii_casecmp(((Contact)b).Name);
			});
			TreeIter iter;
			foreach (Contact contact in contact_list) {
				listmodel.append (out iter);
				listmodel.set (iter, 0, contact.Name);
				if (contact.ID == selected_contact.ID) {
					TreeSelection selection = contacts.get_selection ();
					selection.select_iter (iter);
				}
			}
		}
		
		downloading_contacts = false;
		
		this.show_all ();
	}
	
	private void switch_message_box (Contact contact) {
		message_pane.remove (messages_scroll);
		
		messages_scroll = new ScrolledWindow (null, null);
		messages_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		message_box = new Box (Orientation.VERTICAL, 10);
		message_box.halign = Align.START;
		message_box.set_hexpand (true);
		message_box.margin_left = 10;
		message_box.margin_right = 10;
		
		messages_scroll.add_with_viewport (message_box);
		
		message_pane.pack_start (messages_scroll, true, true, 0);
		
		if (label_contact.parent == message_pane)
			message_pane.remove (label_contact);
		if (phone_number_entry.parent == message_pane)
			message_pane.remove (phone_number_entry);
		
		if (contact.Phone_Number != "") {
			label_contact.set_text (contact.Name + " (" + contact.Phone_Number + ")");
			message_pane.pack_start (label_contact, false, false, 0);
			message_pane.reorder_child (label_contact, 0);
		} else {
			message_pane.pack_start (phone_number_entry, false, false, 0);
			message_pane.reorder_child (phone_number_entry, 0);
		}
		
		foreach (Message msg in contact.Message_List) {
			string sender_name = "Unrecognised sender";
			if (msg.Sender_Phone == "") {
				sender_name = "You";
			} else if (msg.Sender_Phone == contact.Phone_Number) {
				sender_name = contact.Name;
			} else {
				foreach (Contact c in contact_list) {
					if (msg.Sender_Phone == c.Phone_Number) {
						sender_name = c.Name;
						break;
					}
				}
			}
			var time = new DateTime.from_unix_local (msg.Timestamp);
			var myLabel = new Label ("<b>" + sender_name + " (" +
				time.format ("%F %H:%M:%S") + "):</b>\n" + msg.Text);
			myLabel.use_markup = true;
			myLabel.halign = Align.START;
			myLabel.wrap = true;
			myLabel.wrap_mode = Pango.WrapMode.WORD_CHAR;
			myLabel.set_alignment (0, 0);
			message_box.set_border_width (1);
			message_box.pack_start (myLabel, false, true, 0);
			message_box.reorder_child (myLabel, 0);
		}
		
		var buffer = new TextBuffer (new TextTagTable ());
		if (selected_contact.Draft_Message != null)
			buffer.set_text (selected_contact.Draft_Message);
		new_message_entry.set_buffer (buffer);
		
		this.show_all();
	}

}
