const net = require('net');
const commandLineArgs = require('command-line-args');
const tls = require('tls');
const fs = require('fs');
const protocol = require('./protocol.js');
const cliProgress = require('cli-progress');
const _colors = require('colors');
const dbg = require('./debug.js')

process.setMaxListeners(12);

dbg.logAndPrint("Camera Transfer Server (Copyright © 2022, \x1b[34mTeltonika\x1b[0m), version 0.2.3");

const optionDefinitions = [
    { name: 'help', alias: 'h', type: Boolean },
    { name: 'tls', alias: 't', type: Boolean },
    { name: 'port', alias: 'p', type: Number },
    { name: 'cert', alias: 'c' },
    { name: 'key', alias: 'k' },
    { name: 'cam', alias: 'r', type: Number },
    { name: 'meta', alias: 'm', type: String },
]
const args = commandLineArgs(optionDefinitions);

if (args.help == true) {
    dbg.logAndPrint(`usage: cts-win.exe [-h/--help] [--tls] [-p/--port <port>] [-c/--cert <path>] [-k/--key <key>] [-r/--cam <camera id>] [-m/--meta <meta id>]
    
    Argument usage:
       --help, -h        Bring up help menu
       --tls             Enables TLS mode (if this parameter is passed, then cert and key must be provided, otherwise the server works in non-TLS mode)
       --port, -p        Port to listen to
       --cert, -c        Path to root certificate file
       --key, -k         Path to private key file
       --cam, -r         Camera type (0 - Auto, 1 - ADAS, 2 - DualCam, 3 - DSM)
       --meta, -m        Metadata (0 - No metadata, 1 - Before file download)`
       );
    process.exit();
}

/* Check arguments for port */
let port = 0;
if (args.port > 0) {
    port = args.port;
} else {
    dbg.error("Port provided incorrectly / not provided in arguments!");
    process.exit();
}

const CAMERA_TYPE = {
    AUTO: 0,
    ADAS: 1,
    DUALCAM: 2,
    DSM: 3
}

const METADATA_TYPE = {
    NO_METADATA: 0,
    AT_START: 1,
    AT_END: 2,
}

let camera_option = 0;
if (typeof(args.cam) != "undefined") {
    if (args.cam >= 0 && args.cam <= 2) {
        if (args.cam == CAMERA_TYPE.AUTO) {
            dbg.logAndPrint("Chosen auto camera type detection");
        }
        if (args.cam == CAMERA_TYPE.ADAS) {
            dbg.logAndPrint("Chosen ADAS camera type");
        }
        if (args.cam == CAMERA_TYPE.DUALCAM) {
            dbg.logAndPrint("Chosen DualCam camera type");
        }
        if (args.cam == CAMERA_TYPE.DSM) {
            dbg.logAndPrint("Chosen DSM camera type");
        }
        camera_option = args.cam;
    } else {
        dbg.error("Camera type provided incorrectly! " + args.cam);
        process.exit();
    }
} else {
    dbg.logAndPrint("No camera type chosen. Defaulting to auto camera type detection");
}

let metadata_option = 0;
if (typeof(args.meta) != "undefined") {
    if (args.meta == 0 || args.meta == 1) {
        if (args.meta == 0) {
            metadata_option = METADATA_TYPE.NO_METADATA;
            dbg.logAndPrint("No metadata requests will be made");
        }
        if (args.meta == 1) {
            metadata_option = METADATA_TYPE.AT_START;
            dbg.logAndPrint("Metadata will be requested at the start of the file transfer");
        }
    } else {
        dbg.error("Metadata request parameter provided incorrectly!");
        process.exit();
    }
} else {
    dbg.logAndPrint("No metadata requests will be made");
}

let server;
if (args.tls && typeof args.key !== "undefined" && typeof args.cert !== "undefined") {
    dbg.logAndPrint('Starting TLS mode');
    var options = {
        key: fs.readFileSync(args.key),
        cert: fs.readFileSync(args.cert),
    };
    server = tls.createServer(options, handleConnection);
} else {
    dbg.logAndPrint('Starting REGULAR mode');
    var options;
    server = net.createServer(options, handleConnection);
}

//  Start listening to port
server.listen(port, function () {
    dbg.logAndPrint('Listening to ' + server.address()["port"] + ' port');
});

//  Network handler
const buffer_size = 10000;

function handleConnection(connection) {
    const progress_bar = new cliProgress.SingleBar({
        format: '[\x1b[34mSERVER\x1b[0m] Download Progress |' + _colors.blue('{bar}') + '| {percentage}% || {value}/{total} Chunks || ETA: {eta} seconds',
        barsize: 30,
        hideCursor: true
    }, cliProgress.Presets.shades_grey);

    let tcp_buffer = Buffer.alloc(0);
    let remoteAddress = connection.remoteAddress + ':' + connection.remotePort;
    let current_state = protocol.fsm_state.INIT;
    let cmd_size = 0;
    let cmd_id = 0;
    
    let device_info = new protocol.DeviceDescriptor();
    let metadata = new protocol.MetaDataDescriptor();
    dbg.logAndPrint('Client connected: ' + remoteAddress);

    connection.on('data', onConnData);
    connection.once('close', onConnClose);
    connection.on('error', onConnError);
    connection.on('timeout', onConnTimeout);

    function onConnData(data) {
        // Check if there is a TCP buffer overflow
        if (data.length >= buffer_size) {
            dbg.error("Too much data: " + data.length + " >= " + buffer_size);
            return;
        }

        // Add new data to buffer
        tcp_buffer = Buffer.concat([tcp_buffer, data]);

        // A loop to handle case where a packet contains more than one command
        repeat_cycle = true;
        while (repeat_cycle == true) {
            repeat_cycle = false;

            if (tcp_buffer.length < 4) {
                return;
            }

            // Log RX buffer contents
            dbg.log("[RX]: [" + tcp_buffer.toString('hex') + "]");

            // Check CMD validity
            cmd_id = protocol.ParseCmd(tcp_buffer);
            if (protocol.IsCmdValid(cmd_id) == false) {
                tcp_buffer = Buffer.alloc(0);
                return;
            }

            // Get CMD data size
            if (protocol.CmdHasLengthField(cmd_id) == true) {
                cmd_size = tcp_buffer.readUInt16BE(2) + 4;
            } else {
                cmd_size = protocol.GetExpectedCommandLength(cmd_id);
            }

            // If there is not enough data for buffer - return and wait another TCP packet
            if (tcp_buffer.length < cmd_size) {
                return;
            }
            
            current_state = protocol.run_fsm(current_state, connection, cmd_id, tcp_buffer, device_info, metadata, progress_bar, camera_option, metadata_option);

            tcp_buffer = tcp_buffer.slice(cmd_size, tcp_buffer.length);

            repeat_cycle = true;
        }
    }

    function onConnClose() {
        dbg.logAndPrint('Connection from ' + remoteAddress + ' closed');
    }

    function onConnError(err) {
        dbg.logAndPrint('Connection ' + remoteAddress + ' error: ' + err.message);
    }

    function onConnTimeout() {
        dbg.logAndPrint('Connection from ' + remoteAddress + ' timeouted');
    }
}