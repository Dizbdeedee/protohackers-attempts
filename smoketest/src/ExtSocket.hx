import haxe.ds.GenericStack;

class ExtSocket {

    static final mapSock = new haxe.ds.Map<sys.net.Socket,ExtSocket>();

    var buff:GenericStack<haxe.io.Bytes> = new GenericStack();

    final socket:sys.net.Socket;

    public final id:Int = 0;

    public var selectID:Null<Int> = null;

    public static function sockToExt(sock:sys.net.Socket) {
        return mapSock.get(sock);
    }

    public function new(_socket:sys.net.Socket,_id:Int) {
        socket = _socket;
        mapSock.set(_socket,this);
        id = _id;
    }

    public function updateSelectID(_selectID:Int) {
        return selectID = _selectID;
    }

    //you can be untested, too
    public function writeBuff(content:haxe.io.Bytes):Int {
        var written = socket.output.writeBytes(content,0,content.length);
        if (written < content.length) {
            var unwritten = new haxe.io.BytesBuffer();
            unwritten.addBytes(content,written,content.length - written);
            buff.add(unwritten.getBytes());
        }
        return written;
    }

    //untested
    public function catchup() {
        var caughtup = true;
        while (!buff.isEmpty()) {
            var written = writeBuff(buff.pop());
            if (written == 0) {
                caughtup = false;
                break;
            }
        }
        return caughtup;
    }
}