import sys.io.File;
import haxe.io.Bytes;
import haxe.io.Eof;
import sys.net.Host;
import sys.net.Socket;

typedef SelectResults = {
	read : Array<sys.net.Socket>,
	write : Array<sys.net.Socket>,
	others : Array<sys.net.Socket>
}

final DEFAULT_PORT = 23399;

#if debug
final IP = "127.0.0.1";
#else
final IP = "0.0.0.0";
#end
final READ_BUF = 8192;

//untested
function resolvePort() {
	var envPort = Sys.environment().get("PORT");
	return if (envPort != null) {
		Std.parseInt(envPort);
	} else {
		DEFAULT_PORT;
	}
}

final PORT = resolvePort();

final DEBUG_OUTPUT = "debug.txt";

class Main {

	static final serverSocket = new Socket();

	//sockets can't dangle..? closed socket give hang
	static var selectedSockets = [serverSocket];

	static final socketStorage = [serverSocket];

	static var selectResults:SelectResults = {
		read : [serverSocket],
		write : [],
		others : []
	};

	public static function main() {
		#if debug
		var writer = File.write(DEBUG_OUTPUT);
		writer.close();
		#end
		serverSocket.bind(new Host(IP),PORT);
		trace('Bound on ${IP}');
		serverSocket.setBlocking(false);
		serverSocket.listen(15);
		Socket.select([serverSocket],[],[]);
		trace("Starting main loop");
		mainLoop();
	}

	static function clientConnected() {
		var newClient = serverSocket.accept();
		var selectID = selectedSockets.push(newClient) - 1;
		var socketID = socketStorage.push(newClient) - 1;
		var ext = new ExtSocket(newClient,socketID);
		ext.updateSelectID(selectID);
		newClient.setBlocking(false);
		trace('Accepted client! ${socketID}');
	}

	static function updateSelectedSockets() {
		var newSelectedSockets = [];
		for (i in selectedSockets) {
			if (i != null) {
				var newID = newSelectedSockets.push(i) - 1;
				var ext = ExtSocket.sockToExt(i);
				if (ext != null) {
					trace('${ext.id} : ${ext.selectID} -> $newID');
					ext.updateSelectID(newID);
					trace('${ext.id} : ${ext.selectID}');
				}
			}
		}
		selectedSockets = newSelectedSockets;
	}

	static function clientRemoving(sock:sys.net.Socket) {
		var ext = ExtSocket.sockToExt(sock);
		sock.close();
		selectedSockets[ext.selectID] = null;
		updateSelectedSockets();
		trace('Client ${ext.id} EOF');
	}

	static function processRead(readSock:sys.net.Socket) {
		if (readSock == serverSocket) {
			clientConnected();
			return;
		}
		var contentBuffer:Bytes = Bytes.alloc(READ_BUF);
		var realRead = 0;
		try {
			realRead = readSock.input.readBytes(contentBuffer,0,READ_BUF); //bufsize?
		} catch (e:Eof) {
			clientRemoving(readSock);
			return;
		}
		if (realRead > 0) {
			var readBytes = Bytes.alloc(realRead);
			readBytes.blit(0,contentBuffer,0,realRead);
			#if debug
			var readString = contentBuffer.getString(0,realRead);
			trace(readString);
			final debugOut = File.append(DEBUG_OUTPUT);
			debugOut.writeString(readString);
			debugOut.close();
			#end
			recievedContent(readSock,readBytes);
		}

	}

	static function recievedContent(sock:Socket,bytes:haxe.io.Bytes) {
		var ext = ExtSocket.sockToExt(sock);
		ext.catchup();
		ext.writeBuff(bytes);
	}

	//TODO: clean exit..?
	public static function mainLoop() {
		var stop = false;
		do {
			for (readSocket in selectResults.read) {
				processRead(readSocket);
			}
			selectResults = Socket.select(selectedSockets,[],[]);
		} while (!stop);
		trace("Stopped");
	}
}