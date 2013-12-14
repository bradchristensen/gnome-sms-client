using Gtk;
using Notify;
using WebKit;
using Soup;

public class PreferencesWindow : Window {
	public Preferences preferences;
	
	private Label label_no_pairs;
	private Box pairing_vbox;

	public PreferencesWindow (Preferences preferences) {
		this.preferences = preferences;
		
		this.title = "GNOME SMS Intercepter Preferences";
		this.window_position = WindowPosition.CENTER_ON_PARENT;
		this.set_skip_taskbar_hint (true);
		this.set_default_size (800, 500);
		this.set_type_hint (Gdk.WindowTypeHint.DIALOG);
		
		var notebook = new Notebook ();
		
		var tab_pairing = new Box (Orientation.HORIZONTAL, 10);
		tab_pairing.margin = 10;
		var tab_settings = new Box (Orientation.HORIZONTAL, 10);
		tab_settings.margin = 10;

		var paired_list_container = new Box (Orientation.VERTICAL, 0);
		var paired_treeview = new TreeView ();
		var paired_scroll = new ScrolledWindow (null, null);
		paired_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		paired_scroll.set_min_content_width (150);
		paired_scroll.set_shadow_type (ShadowType.IN);
		paired_scroll.add (paired_treeview);

		var paired_listmodel = new ListStore (1, typeof (string));
		paired_treeview.set_model (paired_listmodel);
		paired_treeview.set_headers_visible (false);
		paired_treeview.insert_column_with_attributes (-1, "Device",
			new CellRendererText (), "text", 0);
		
		var paired_toolbar = new Toolbar ();
		paired_toolbar.get_style_context ().add_class (STYLE_CLASS_INLINE_TOOLBAR);
		paired_toolbar.set_icon_size (IconSize.MENU);
		var add_paired_button = new ToolButton (null, null);
		add_paired_button.set_icon_name ("list-add-symbolic");
		var remove_paired_button = new ToolButton (null, null);
		remove_paired_button.set_icon_name ("list-remove-symbolic");
		paired_toolbar.add (add_paired_button);
		paired_toolbar.add (remove_paired_button);
		
		paired_list_container.pack_start (paired_scroll, true, true, 0);
		paired_list_container.pack_start (paired_toolbar, false, true, 0);
		
		label_no_pairs = new Label ("Add a new device using the controls "
			+ "to the left.");
		
		pairing_vbox = new Box (Orientation.VERTICAL, 10);
		if (preferences.devices.size == 0) {
			pairing_vbox.pack_start (label_no_pairs, true, true, 0);
			remove_paired_button.set_sensitive (false);
		}
		
		tab_pairing.pack_start (paired_list_container, false, false, 0);
		tab_pairing.pack_start (pairing_vbox, true, true, 0);
		
		notebook.append_page (tab_pairing, new Label ("Device Pairing"));
		notebook.append_page (tab_settings, new Label ("Application"));
		
		var button_layout = new ButtonBox (Orientation.HORIZONTAL);
		button_layout.set_layout (ButtonBoxStyle.END);
		
		var button_close = new Button.from_stock (Stock.CLOSE);
		button_close.clicked.connect ( () => {
			this.destroy ();
		});
		
		button_layout.pack_start (button_close, false, false, 0);
		
		var vbox = new Box (Orientation.VERTICAL, 10);
		vbox.margin = 12;
		vbox.pack_start (notebook, true, true, 0);
		vbox.pack_start (button_layout, false, false, 0);
		
		this.add (vbox);
	}
}
