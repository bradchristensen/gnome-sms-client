using Gtk;
using Notify;
using WebKit;
using Soup;

public class Utils {

	public static string random_string (int len) {
		string dictionary = "abcdefghijklmnopqrstuvw0123456789";
		string rstr = "";
		for (int i = 0; i < len; i++) {
			int selector = Random.int_range (0, dictionary.length);
			rstr += dictionary.substring (selector, 1);
		}
		return rstr;
	}
	
	public static string soup_get_json (string url) {
		var session = new Soup.SessionSync ();
		var message = new Soup.Message ("GET", url);
		session.send_message (message);
		return (string)message.response_body.flatten ().data;
	}

}
