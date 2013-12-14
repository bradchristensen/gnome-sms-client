// Current (dev):
// valac --vapidir=../vapi --pkg gtk+-3.0 --pkg libnotify --pkg gio-2.0 --pkg gee-1.0 --pkg gmodule-2.0 --pkg libxml-2.0 --pkg libwebkitgtk-3.0 --pkg libsoup-2.4 --pkg json-glib-1.0 --thread ./main.vala

// Fresh install requires libnotify-dev, libjson-glib-dev, libgtk-3-dev, libwebkitgtk-3.0-dev

// Debug: -g --save-temps
// echo "blub" | nc localhost 3333

using Gtk;
using Notify;
using WebKit;
using Soup;

public class Application {

	public static int main (string[] args) {
		
		Gtk.init (ref args);
		
		Notify.init ("GNOME SMS Intercepter");
		
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
