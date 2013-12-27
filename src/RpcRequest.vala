using Soup;

public class RpcRequest {
	private static RpcRequest request_instance;
	private HashTable<string, string> args;
	private RpcRequest () {
		args = new HashTable<string, string> (str_hash, str_equal);
	}
	public static RpcRequest get_instance () {
		if (null == request_instance)
		{
			request_instance = new RpcRequest();
		}
		return request_instance;
	}
	public void add_parameter (string name, string val) {
		args.insert (name, val);
	}
	private string prepare (string uri) {
		Soup.URI myuri = new Soup.URI(uri);
		myuri.set_query_from_form (args); //Use soup to handle encoding
		string ret = myuri.query;
		myuri = null;
		return ret;
	}
	public string send (string method, string uri) {
		lock (request_instance) {
			if (!Thread.supported ()) {
				stderr.printf("Cannot run without threads.\n");
			}
			uint8[] formdata = (uint8[])prepare (uri);
			formdata.length = prepare (uri).length;
			var session = new Soup.SessionSync ();
			var message = new Soup.Message (method, uri);
			message.set_request("application/x-www-form-urlencoded", MemoryUse.COPY, formdata);
			session.send_message (message);
			message.response_headers.foreach ((name, val) => {
				stdout.printf ("Name: %s -> Value: %s\n", name, val);
			});
			var response = (string)message.response_body.flatten ().data;
			var response_length = (long)message.response_body.length;
			stdout.printf ("Msg length: %ld\n%s\n", response_length, response);
			message = null;
			session = null;
			args = new HashTable<string, string> (str_hash, str_equal);
			return response;
		}
	}
}
