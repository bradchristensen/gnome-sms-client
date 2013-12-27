public class Contact {
	public string ID;
	public string Name;
	public string Phone_Number;
	public string Email_Address;
	public Gee.ArrayList<string> Phone_Numbers;
	public string Draft_Message;
	public Gee.ArrayList<Message> Message_List;
	
	public Contact (string id, string name, Gee.ArrayList<string> new_numbers) {
		ID = id;
		Name = name;
		Phone_Numbers = new_numbers;
		Message_List = new Gee.ArrayList<Message> ();
		string longest_number = "";
		foreach (string number in Phone_Numbers) {
			if (number.length > longest_number.length)
				longest_number = number;
		}
		Phone_Number = longest_number;
	}
	
	public void send_message (int64 timestamp, string text) {
		Message_List.add (new Message (random_string (32), "", timestamp, text));
	}
	
	public void receive_message (string sender_phone, int64 timestamp, string text) {
		Message_List.add (new Message (random_string (32), sender_phone, timestamp, text));
	}

	private static string random_string (int len) {
		string dictionary = "abcdefghijklmnopqrstuvw0123456789";
		string rstr = "";
		for (int i = 0; i < len; i++) {
			int selector = Random.int_range (0, dictionary.length);
			rstr += dictionary.substring (selector, 1);
		}
		return rstr;
	}
}
