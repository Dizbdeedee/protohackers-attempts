import Main.PORT;
import sys.net.Host;
import sys.net.Socket;
import haxe.Resource;

class Test {

    static final content = Resource.getBytes("content");

    static final CONNECTION_TIME = Std.int(Math.random() * 30 + 30);

    public static function main() {
        var stop = false;
        var connTries = 0;
        var listenSocket = new Socket();
        do {
            try {
                listenSocket.connect(new Host(Host.localhost()),PORT);
            } catch (e) {
                connTries++;
                trace('Failed to connect... connTries $connTries');
                if (connTries > 10) {
                    stop = true;
                    break;
                }
            }
            trace('Aquired. Connection time $CONNECTION_TIME');
            //listenSocket.write()
            
            
        } while (!stop);
        trace("Failed to connect after 10 tries");
    }
}