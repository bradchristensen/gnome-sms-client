public class Application {

	public static int main (string[] args) {
		
		Gtk.init (ref args);
		
		Notify.init ("GNOME SMS Client");
		
		var window = new MainWindow ();
		//window.send_button.grab_default ();
		window.destroy.connect (terminate_app);
	
		Gtk.main ();
		
		return 0;
	}
	
	static void terminate_app () {
		Notify.uninit ();
		Gtk.main_quit ();
	}

}
