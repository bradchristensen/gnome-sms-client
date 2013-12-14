public class Message {
	public string ID;
	public string Sender_Phone;
	public int64 Timestamp;
	public string Text;
	
	public Message (string id, string sender_phone, int64 timestamp, string text) {
		ID = id;
		Sender_Phone = sender_phone;
		Timestamp = timestamp;
		Text = text;
	}
}
