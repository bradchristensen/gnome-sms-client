public class Device {
	public string Name;
	public Contact Owner;
	public string IP;
	public int Port;
	public string Password;
	
	public Device (string ip, int port, string password, string name, Contact owner) {
		IP = ip;
		Port = port;
		Password = password;
		Name = name;
		Owner = owner;
	}
}
