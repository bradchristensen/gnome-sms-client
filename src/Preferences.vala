public class Preferences {
	private File settings_dir;
	private File settings_file;
	private File contacts_file;
	
	public string access_token;
	public string refresh_token;
	
	public Gee.ArrayList<Device> devices;
	public Device current_device;
	
	private bool validate_files () {
		var home_dir = File.new_for_path (Environment.get_home_dir ());
		settings_file = home_dir.get_child (".config").
			get_child ("gnome-sms-client").get_child ("settings.json");
		settings_dir = settings_file.get_parent ();
		if (!settings_dir.query_exists ()) {
			try {
				settings_dir.make_directory_with_parents ();
			} catch (Error er) {
				stderr.printf ("File IO error: %s\n", er.message);
			}
		}
		
		if (settings_dir.query_exists ()) {
			if (!settings_file.query_exists ()) {
				try {
					settings_file.create (FileCreateFlags.NONE);
				} catch (Error era) {
					stderr.printf ("File IO error: %s\n", era.message);
				}
			}
			contacts_file = settings_dir.get_child ("contact_list.json");
			if (!contacts_file.query_exists ()) {
				try {
					contacts_file.create (FileCreateFlags.NONE);
				} catch (Error ec) {
					stderr.printf ("File IO error: %s\n", ec.message);
				}
			}
			if (settings_file.query_exists () && contacts_file.query_exists ())
				return true;
		}
		
		return false;
	}
	
	public bool load () {
		devices = new Gee.ArrayList<Device> ();
		
		if (validate_files ()) {
			try {
				var dis = new DataInputStream (settings_file.read ());
				string settings_json = "";
				string line;
				while ((line = dis.read_line (null)) != null) {
					settings_json += line + "\n";
				}
				
				var parser = new Json.Parser ();
				parser.load_from_data (settings_json, -1);
				if (parser.get_root () != null) {
					var root_object = parser.get_root ().get_object ();
					if (root_object != null)
						refresh_token = root_object.get_string_member ("refresh_token");
				}
			} catch (Error e) {
				stderr.printf ("%s\n", e.message);
				return false;
			}
			return true;
		}
		return false;
	}
	
	public bool save_refresh_token () {
		if (validate_files ()) {
			try {
				string settings_json = "";
				string line;
				var dis = new DataInputStream (settings_file.read ());
				while ((line = dis.read_line (null)) != null) {
					settings_json += line + "\n";
				}
			
				var parser = new Json.Parser ();
				parser.load_from_data (settings_json, -1);
				if (parser.get_root() != null) {
					Json.Object? root_object = parser.get_root ().get_object ();
					var generator = new Json.Generator ();
					if (root_object != null) {
						root_object.set_string_member ("refresh_token", refresh_token);
						generator.set_root (parser.get_root ());
					} else {
						// file is more or less empty; create new json root
						var root = new Json.Node (Json.NodeType.OBJECT);
						root_object = new Json.Object ();
						root_object.set_string_member ("refresh_token", refresh_token);
						root.set_object (root_object);
						generator.set_root (root);
					}
					generator.to_file (settings_file.get_path ());
				}
			} catch (Error e) {
				stderr.printf ("%s\n", e.message);
				return false;
			}
			return true;
		} else {
			stderr.printf ("Settings file could neither be found nor created.");
		}
		return false;
	}
	
	public Gee.ArrayList<Contact> load_contact_list () {
		Gee.ArrayList<Contact> contact_list = new Gee.ArrayList<Contact> ();
		if (validate_files ()) {
			try {
				var dis = new DataInputStream (contacts_file.read ());
				string contacts_json = "";
				string line;
				while ((line = dis.read_line (null)) != null) {
					contacts_json += line + "\n";
				}
			
				if (contacts_json != "") {
					var parser = new Json.Parser ();
					parser.load_from_data (contacts_json, -1);
					var root_object = parser.get_root ().get_object ();
					var contacts_array = root_object.get_array_member ("contact_list");
					foreach (var contact_e in contacts_array.get_elements ()) {
						var contact_object = contact_e.get_object ();
						string contact_id = contact_object.get_string_member ("ID");
						string contact_name = contact_object.get_string_member ("Name");
						Gee.ArrayList<string> phone_numbers = new Gee.ArrayList<string> ();
						foreach (var phone_number in contact_object.get_array_member ("Phone_Numbers").get_elements ()) {
							phone_numbers.add (phone_number.get_string ());
						}
						contact_list.add (new Contact (contact_id, contact_name, phone_numbers));
					}
				}
			} catch (Error e) {
				stderr.printf ("Likely a Json error: %s\n", e.message);
			}
		}
		return contact_list;
	}
	
	public bool save_contact_list (Gee.ArrayList<Contact> contact_list) {
		var contacts_file = settings_dir.get_child ("contact_list.json");
		if (validate_files ()) {
			try {
				var generator = new Json.Generator ();
				var root = new Json.Node (Json.NodeType.OBJECT);
				var root_object = new Json.Object ();
				var contact_list_array = new Json.Array ();
				foreach (Contact contact in contact_list) {
					var contact_object = new Json.Object ();
					contact_list_array.add_object_element (contact_object);
					contact_object.set_string_member ("ID", contact.ID);
					contact_object.set_string_member ("Name", contact.Name);
					contact_object.set_string_member ("Phone_Number", contact.Phone_Number);
					contact_object.set_string_member ("Email_Address", contact.Email_Address);
					var phone_numbers = new Json.Array ();
					foreach (string phone_number in contact.Phone_Numbers) {
						phone_numbers.add_string_element (phone_number);
					}
					contact_object.set_array_member ("Phone_Numbers", phone_numbers);
					stdout.printf ("Saving: %s\n", contact.Name);
				}
				root_object.set_array_member ("contact_list", contact_list_array);
				root.set_object (root_object);
				generator.set_root (root);
				generator.pretty = true;
				generator.to_file (contacts_file.get_path ());
			} catch (Error e) {
				stderr.printf ("Error: %s\n", e.message);
				return false;
			}
			return true;
		} else {
			stderr.printf ("Contacts file could neither be found nor created.");
		}
		return false;
	}
}
