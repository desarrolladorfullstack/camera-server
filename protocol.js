const fs = require('fs');
const process = require('process');
const { exec } = require("child_process");
const cliProgress = require('cli-progress');
const _colors = require('colors');
const dbg = require('./debug.js');
const { Console } = require('console');


/* Constants */
const FSM_STATE = {
    WAIT_FOR_CMD: 0,
    INIT: 1,
    RECEIVE_DATA: 2,
    FINISH_RECEIVING: 3,
    REPEAT_PACKET: 4,
    SEND_METADATA_REQUEST: 5,
    SEND_FILEPATH: 6,
    LOOK_FOR_FILES: 7,
    SEND_COMPLETE: 8,
    SEND_END: 9,
    END: 10,
};

exports.fsm_state = FSM_STATE;

const DUALCAM_FILE_PATH = {
    DUALCAM_PHOTO_FRONT: "%photof",
    DUALCAM_PHOTO_REAR: "%photor",
    DUALCAM_VIDEO_FRONT: "%videof",
    DUALCAM_VIDEO_REAR: "%videor",
};

const CAMERA_TYPE = {
    AUTO: 0,
    ADAS: 1,
    DUALCAM: 2,
    DSM: 3,
}

const METADATA_TYPE = {
    NO_METADATA: 0,
    AT_START: 1,
}

const CMD_ID = {
    INIT: 0,
    START: 1,
    SYNC: 3,
    DATA: 4,
    METADATA: 11,
    FILEPATH: 13,
}

function Device() {
    this.fsm_state = FSM_STATE.WAIT_FOR_CMD
    this.deviceDirectory = "";
    this.filename = "";
    this.actual_crc = 0;
    this.received_packages = 0;
    this.total_packages = 0;
    this.extension_to_use = "";
    this.query_file = 0;
    this.file_buff = Buffer.alloc(0);
    this.camera = CAMERA_TYPE.AUTO;
    this.metadata_type = METADATA_TYPE.NO_METADATA;
}

exports.DeviceDescriptor = Device;
Device.prototype.setDeviceDirectory = function (directory) {
    this.deviceDirectory = directory;
}

Device.prototype.getDeviceDirectory = function () {
    return this.deviceDirectory;
}

Device.prototype.setCurrentFilename = function (filename) {
    this.filename = filename;
}

Device.prototype.getCurrentFilename = function () {
    return this.filename;
}

Device.prototype.setLastCRC = function (crc) {
    this.actual_crc = crc;
}

Device.prototype.getLastCRC = function () {
    return this.actual_crc;
}

Device.prototype.incrementReceivedPackageCnt = function (bytes_received) {
    this.received_packages += bytes_received;
}

Device.prototype.getReceivedPackageCnt = function () {
    return this.received_packages;
}

Device.prototype.setReceivedPackageCnt = function (package_cnt) {
    this.received_packages = package_cnt;
}

Device.prototype.resetReceivedPackageCnt = function () {
    this.received_packages = 0;
}

Device.prototype.setTotalPackages = function (pkg) {
    this.total_packages = pkg;
}

Device.prototype.getTotalPackages = function () {
    return this.total_packages;
}

Device.prototype.getExtension = function () {
    return this.extension_to_use;
}

Device.prototype.setExtension = function (extension) {
    this.extension_to_use = extension;
}

Device.prototype.setFileToDL = function (file) {
    this.query_file = file;
}

Device.prototype.getFileToDL = function (file) {
    return this.query_file;
}

Device.prototype.getFileBuffer = function () {
    return this.file_buff;
}

Device.prototype.addToBuffer = function (data) {
    this.file_buff = Buffer.concat([this.file_buff, data])
}

Device.prototype.clearBuffer = function () {
    this.file_buff = Buffer.alloc(0);
}

Device.prototype.setCameraType = function (type) {
    this.camera = type;
}

Device.prototype.getCameraType = function () {
    return this.camera;
}

let DUALCAM_ADAS_TRIGGER_SOURCE = {
    0: "SERVER REQUEST",
    1: "DIN1",
    2: "DIN2",
    3: "CRASH",
    4: "TOWING",
    5: "IDLING",
    6: "GEOFENCE",
    7: "UNPLUG",
    8: "GREEN DRIVING",
    9: "PERIODIC",
}

let DSM_TRIGGER_SOURCE = {
    0: "NONE",
    1: "DIN1",
    2: "DIN2",
    3: "DIN3",
    4: "DIN4",
    5: "CRASH",
    6: "TOWING",
    7: "IDLING",
    8: "GEOFENCE",
    9: "UNPLUG",
    10: "GREEN DRIVING",
    11: "SERVER",
    12: "PERIODIC",
    13: "DSM EVENT",
}

let DUALCAM_FILE_TYPE = {
    4:  "FRONT PHOTO",
    8:  "REAR PHOTO",
    16: "FRONT VIDEO",
    32: "REAR VIDEO",
}

let ADAS_FILE_TYPE = {
    0:  "VIDEO",
    1:  "SNAPSHOT",
    2:  "CURRENT SNAPSHOT",
}

function MetaData() {
    this.command_version = "";   //1 byte
    this.file_type = "";         //1 byte
    this.timestamp = "";         //8 bytes (uint, seconds)
    this.trigger_source = "";    //1 byte
    this.length = "";            //2 bytes
    this.framerate = "";         //1 byte
    this.timezone = "";          //2 bytes (int, minutes)
    this.latitude = "";          //8 bytes
    this.longitude = "";         //8 bytes
    this.events = "";            //2 bytes
    this.driver_name = "";       //10 bytes
}

exports.MetaDataDescriptor = MetaData;

MetaData.prototype.reset = function () {
    this.command_version = "";
    this.file_type = "";
    this.timestamp = "";
    this.trigger_source = "";
    this.length = "";
    this.framerate = "";
    this.timezone = "";
    this.latitude = "";
    this.longitude = "";
    this.events = "";
    this.driver_name = "";
}

MetaData.prototype.getString = function (camera) {
    let string;
    if (camera == CAMERA_TYPE.DUALCAM) {
        string =     "Cmd version: \t" + this.command_version + '\n';
        string +=    "File type: \t" + this.file_type + '\n';
        string +=    "Time (UTC+0): \t" + this.timestamp + '\n';
        string +=    "Trigger: \t" + this.trigger_source + '\n';
        string +=    "Length (s): \t" + this.length + '\n';
        string +=    "Framerate: \t" + this.framerate + '\n';
        string +=    "Timezone (m): \t" + this.timezone + '\n';
        string +=    "Latitude: \t" + this.latitude + '\n';
        string +=    "Longitude: \t" + this.longitude + '\n';
    }
    if (camera == CAMERA_TYPE.ADAS) {
        string =     "Time (UTC+0): \t" + this.timestamp + '\n';
        string +=    "File type: \t" + this.file_type + '\n';
        string +=    "Trigger: \t" + this.trigger_source + '\n';
        string +=    "Length (s): \t" + this.length + '\n';
        string +=    "Latitude: \t" + this.latitude + '\n';
        string +=    "Longitude: \t" + this.longitude + '\n';
    }
    if (camera == CAMERA_TYPE.DSM) {
        string =     "Time (UTC+0): \t" + this.timestamp + '\n';
        string +=    "File type: \t" + this.file_type + '\n';
        string +=    "Trigger: \t" + this.trigger_source + '\n';
        string +=    "Latitude: \t" + this.latitude + '\n';
        string +=    "Longitude: \t" + this.longitude + '\n';
        string +=    "Events: \t" + this.dsm_events + '\n';
        string +=    "Driver: \t" + this.driver_name + '\n';
    }
    return string;
}

MetaData.prototype.parseData = function (metadata, device_info, raw_data) {
    metadata.reset();
    if (device_info.getCameraType() == CAMERA_TYPE.DUALCAM) {
        metadata.setCommandVersion(raw_data.slice(0, 1));                               //1 byte
        metadata.setFileType(raw_data.slice(1, 2), device_info.getCameraType());        //1 byte
        metadata.setTimestamp(raw_data.slice(2, 10), device_info.getCameraType());      //8 bytes (uint, seconds)
        metadata.setTriggerSource(raw_data.slice(10, 11), device_info.getCameraType()); //1 byte
        metadata.setLength(raw_data.slice(11, 13), device_info.getCameraType());        //2 bytes
        metadata.setFramerate(raw_data.slice(13, 14));                                  //1 byte
        metadata.setTimezone(raw_data.slice(14, 16));                                   //2 bytes (int, minutes)
        metadata.setLatitude(raw_data.slice(16, 24), device_info.getCameraType());      //8 bytes
        metadata.setLongitude(raw_data.slice(24, 32), device_info.getCameraType());     //8 bytes
    }

    if (device_info.getCameraType() == CAMERA_TYPE.ADAS) {
        metadata.setTimestamp(raw_data.slice(0, 4), device_info.getCameraType());       //4 bytes (uint, seconds)
        metadata.setFileType(raw_data.slice(4, 5), device_info.getCameraType());        //1 byte
        metadata.setTriggerSource(raw_data.slice(5, 6), device_info.getCameraType());   //1 byte
        metadata.setLatitude(raw_data.slice(6, 10), device_info.getCameraType());       //4 bytes
        metadata.setLongitude(raw_data.slice(10, 14), device_info.getCameraType());     //4 bytes
        metadata.setLength(raw_data.slice(14, 15), device_info.getCameraType());        //1 byte
    }

    if (device_info.getCameraType() == CAMERA_TYPE.DSM) {
        metadata.setTimestamp(raw_data.slice(0, 4), device_info.getCameraType());       //4 bytes (uint, seconds)
        metadata.setFileType(raw_data.slice(4, 5), device_info.getCameraType());        //1 byte
        metadata.setTriggerSource(raw_data.slice(5, 6), device_info.getCameraType());   //1 byte
        metadata.setLatitude(raw_data.slice(6, 10), device_info.getCameraType());       //4 bytes
        metadata.setLongitude(raw_data.slice(10, 14), device_info.getCameraType());     //4 bytes
        metadata.setDSMEvents(raw_data.slice(14, 16), device_info.getCameraType());     //2 bytes
        metadata.setDriverName(raw_data.slice(16, 26), device_info.getCameraType());    //10 bytes
    }
}

MetaData.prototype.setCommandVersion = function (command_version) {
    this.command_version = command_version.readUInt8(0).toString(10);
}

MetaData.prototype.getCommandVersion = function () {
    return this.command_version;
}

MetaData.prototype.setFileType = function (file_type, camera) {
    if (camera == CAMERA_TYPE.DUALCAM) {
        this.file_type = DUALCAM_FILE_TYPE[file_type.readUInt8(0)] + " (" + file_type.readUInt8(0).toString(10) + ")";
    }
    if (camera == CAMERA_TYPE.ADAS) {
        this.file_type = ADAS_FILE_TYPE[file_type.readUInt8(0)] + " (" + file_type.readUInt8(0).toString(10) + ")";
    }
    if (camera == CAMERA_TYPE.DSM) {
        this.file_type = ADAS_FILE_TYPE[file_type.readUInt8(0)] + " (" + file_type.readUInt8(0).toString(10) + ")";
    }
}

MetaData.prototype.getFileType = function () {
    return this.file_type;
}

MetaData.prototype.setTimestamp = function (timestamp, camera) {
    if (camera == CAMERA_TYPE.DUALCAM) {
        var date = new Date( Number(timestamp.readBigUInt64BE(0)));
        this.timestamp = date.toISOString().replace(/[TZ]/g, ' ') + "(" + timestamp.readBigUInt64BE(0).toString(10) + ")";
    }
    if (camera == CAMERA_TYPE.ADAS) {
        var date = new Date( Number(timestamp.readUInt32BE(0)) * 1000);
        this.timestamp = date.toISOString().replace(/[TZ]/g, ' ') + "(" + timestamp.readUInt32BE(0).toString(10) + ")";
    }
    if (camera == CAMERA_TYPE.DSM) {
        var date = new Date( Number(timestamp.readUInt32BE(0)) * 1000);
        this.timestamp = date.toISOString().replace(/[TZ]/g, ' ') + "(" + timestamp.readUInt32BE(0).toString(10) + ")";
    }
}

MetaData.prototype.getTimestamp = function () {
    return this.timestamp;
}

MetaData.prototype.setTriggerSource = function (trigger_source, camera) {
    if (camera == CAMERA_TYPE.DUALCAM) {
        this.trigger_source = DUALCAM_ADAS_TRIGGER_SOURCE[trigger_source.readUInt8(0)] + " (" + trigger_source.readUInt8(0).toString(10) + ")";
    }
    if (camera == CAMERA_TYPE.ADAS) {
        this.trigger_source = DUALCAM_ADAS_TRIGGER_SOURCE[trigger_source.readUInt8(0)] + " (" + trigger_source.readUInt8(0).toString(10) + ")";
    }
    if (camera == CAMERA_TYPE.DSM) {
        this.trigger_source = DSM_TRIGGER_SOURCE[trigger_source.readUInt8(0)] + " (" + trigger_source.readUInt8(0).toString(10) + ")";
    }
}

MetaData.prototype.getTriggerSource = function () {
    return this.trigger_source;
}

MetaData.prototype.setLength = function (length, camera) {
    if (camera == CAMERA_TYPE.DUALCAM) {
        this.length = length.readUInt16BE(0).toString(10);
    }
    if (camera == CAMERA_TYPE.ADAS) {
        this.length = length.readUInt8(0).toString(10);
    }
}

MetaData.prototype.getLength = function () {
    return this.length;
}

MetaData.prototype.setFramerate = function (framerate) {
    this.framerate = framerate.readUInt8(0).toString(10);
}

MetaData.prototype.getFramerate = function () {
    return this.framerate;
}

MetaData.prototype.setTimezone = function (timezone) {
    this.timezone = timezone.readInt16BE(0).toString(10);
}

MetaData.prototype.getTimezone = function () {
    return this.timezone;
}

MetaData.prototype.setLatitude = function (latitude, camera) {
    if (camera == CAMERA_TYPE.DUALCAM) {
        this.latitude = latitude.readDoubleBE(0).toString(10);
    }
    if (camera == CAMERA_TYPE.ADAS) {
        var lat = latitude.readUInt32BE(0) / 1000000;
        this.latitude = lat.toString(10) + " (" + latitude.readUInt32BE(0) + ")";
    }
    if (camera == CAMERA_TYPE.DSM) {
        var lat = latitude.readUInt32BE(0) / 1000000;
        this.latitude = lat.toString(10) + " (" + latitude.readUInt32BE(0) + ")";
    }
}

MetaData.prototype.getLatitude = function () {
    return this.latitude;
}

MetaData.prototype.setLongitude = function (longitude, camera) {
    if (camera == CAMERA_TYPE.DUALCAM) {
        this.longitude = longitude.readDoubleBE(0).toString(10);
    }
    if (camera == CAMERA_TYPE.ADAS) {
        var lon = longitude.readUInt32BE(0) / 1000000;
        this.longitude = lon.toString(10) + " (" + longitude.readUInt32BE(0) + ")";
    }
    if (camera == CAMERA_TYPE.DSM) {
        var lon = longitude.readUInt32BE(0) / 1000000;
        this.longitude = lon.toString(10) + " (" + longitude.readUInt32BE(0) + ")";
    }
}

MetaData.prototype.getLongitude = function () {
    return this.longitude;
}

MetaData.prototype.setDSMEvents = function (dsm_events, camera) {
    if (camera == CAMERA_TYPE.DSM) {
        let dsm_number = dsm_events[0] << 8 | dsm_events [1];
        let events_string = "";
        events_string += ((dsm_number & (1 << 0)) > 0 ? "DROWSINESS " : "");
        events_string += ((dsm_number & (1 << 1)) > 0 ? "DISTRACTION " : "");
        events_string += ((dsm_number & (1 << 2)) > 0 ? "YAWNING " : "");
        events_string += ((dsm_number & (1 << 3)) > 0 ? "PHONE " : "");
        events_string += ((dsm_number & (1 << 4)) > 0 ? "SMOKING " : "");
        events_string += ((dsm_number & (1 << 5)) > 0 ? "DRIVER ABSENCE " : "");
        events_string += ((dsm_number & (1 << 6)) > 0 ? "MASK " : "");
        events_string += ((dsm_number & (1 << 7)) > 0 ? "SEAT BELT " : "");
        events_string += ((dsm_number & (1 << 8)) > 0 ? "G-SENSOR " : "");
        this.dsm_events = events_string + "(" + (dsm_number >>> 0).toString(2) + ")";
    }
}

MetaData.prototype.getDSMEvents= function () {
    return this.dsm_events;
}

const toString = (bytes) => {
    var result = '';
  for (var i = 0; i < bytes.length; ++i) {
        const byte = bytes[i];
        const text = byte.toString(16);
      result += (byte < 16 ? '%0' : '%') + text;
  }
  return decodeURIComponent(result);
};

function reverseString(str) {
    var newString = "";
    for (var i = str.length - 1; i >= 0; i--) {
        newString += str[i];
    }
    return newString;
}

MetaData.prototype.setDriverName = function (driver_name, camera) {
    if (camera == CAMERA_TYPE.DSM) {
        this.driver_name = reverseString(toString(driver_name));
    }
}

MetaData.prototype.getDriverName = function () {
    return this.driver_name;
}

function crc16_generic(init_value, poly, data) {
    let RetVal = init_value;
    let offset;

    for (offset = 0; offset < data.length; offset++) {
        let bit;
        RetVal ^= data[offset];
        for (bit = 0; bit < 8; bit++) {
            let carry = RetVal & 0x01;
            RetVal >>= 0x01;
            if (carry) {
                RetVal ^= poly;
            }
        }
    }
    return RetVal;
}

exports.ParseCmd = function (a) {
    return a.readUInt16BE(0);
};

exports.CmdHasLengthField = function getCmdLengthOpt(cmd_id) {
    if (cmd_id == 4 || cmd_id == 5 || cmd_id == 13 || cmd_id == 11) {
        return true;
    }
    return false;
};

exports.IsCmdValid = function doesCmdExist(cmd_id) {
    if (cmd_id < 15) {
        return true;
    } else {
        return false;
    }
};

exports.GetExpectedCommandLength = function (cmd) {
    let return_value = 0;
    switch (cmd) {
        case 0:
            return_value = 16;
            break;
        case 1:
            return_value = 10;
            break;
        case 3:
            return_value = 8;
            break;
    }
    return return_value;
};

function ParseFilePath(a) {
    let path = a.toString().substring(4);
    return path;
};
let file_separator = "\\";
function ConvertVideoFile(directory, filename, extension, metadata, metadata_option) {
    framerate = "25";
    if (metadata_option == METADATA_TYPE.AT_START) {
        framerate = metadata.getFramerate(); 
    }
    file_separator = "/";
    let form_command = "ffmpeg -hide_banner -loglevel quiet -r " + framerate + " -i \"" + directory + file_separator + filename + extension + "\" -ss 00:00:0.9 -c:a copy -c:v libx264 \"" + directory + file_separator + filename + ".mp4\"";
    exec(form_command, (error, stdout, stderr) => {
        if (error) {
            dbg.error(`Error: ${error.message}`);
            return;
        }
        if (stderr) {
            dbg.error(`Stderr: ${stderr}`);
            return;
        }
    });
}

let sync_received = false;

const media_folder = 'downloads';
exports.run_fsm = function (current_state, connection, cmd_id, data_buffer, device_info, metadata, progress_bar, camera_option, metadata_option) {
    let file_available = false;
    switch (cmd_id) {
        case CMD_ID.START: {
            switch (device_info.getCameraType()) {
                case CAMERA_TYPE.DUALCAM: {
                    device_info.setTotalPackages(data_buffer.readUInt32BE(4));
                    dbg.logAndPrint("Camera: DUALCAM");
                    break;
                }
                case CAMERA_TYPE.ADAS: {
                    device_info.setTotalPackages(data_buffer.readUInt32BE(4));
                    dbg.logAndPrint("Camera: ADAS");
                    break;
                }
                case CAMERA_TYPE.DSM: {
                    device_info.setTotalPackages(data_buffer.readUInt32BE(4));
                    dbg.logAndPrint("Camera: DSM");
                    break;
                }
            }
            if (device_info.getTotalPackages() == 0) {
                dbg.logAndPrint("No packages are left for this file");
                finish_comms = true;
            } else {
                dbg.logAndPrint("Total packages incoming for this file: " + device_info.getTotalPackages());
                const query = Buffer.from([0, 2, 0, 4, 0, 0, 0, 0]);
                connection.write(query);
                dbg.log('[TX]: [' + query.toString('hex') + ']');
                current_state = FSM_STATE.WAIT_FOR_CMD;
                let total_pkg = device_info.getTotalPackages();
                progress_bar.start(total_pkg, 0);
            }
            break;
        }

        case CMD_ID.SYNC: {
            dbg.log("Sync has been received!");
            sync_received = true;
            current_state = FSM_STATE.WAIT_FOR_CMD;
            break;
        }

        case CMD_ID.DATA: {
            if (sync_received == false) {
                return FSM_STATE.WAIT_FOR_CMD;
            }
            /* Read data length minus CRC */
            let data_len = data_buffer.readUInt16BE(2) - 2;
            /* Get raw file data */
            let raw_file = data_buffer.slice(4, 4 + data_len);
            /* Calculate CRC + add sum of last packet */
            let computed_crc = crc16_generic(device_info.getLastCRC(), 0x8408, data_buffer.slice(4, 4 + data_len));
            /* Read actual CRC in packet */
            let actual_crc = data_buffer.readUInt16BE(4 + data_len);
            /* Calculate CRC and display with actual */

            dbg.log("CRC = Computed: " + computed_crc + ", Actual : " + actual_crc);

            if (computed_crc != actual_crc) {
                dbg.error("CRC mismatch!");
                device_info.setLastCRC(0);
                current_state = FSM_STATE.REPEAT_PACKET;
            } else {
                switch (device_info.getCameraType()) {
                    case CAMERA_TYPE.DUALCAM: {
                        device_info.incrementReceivedPackageCnt(1);
                        break;
                    }
                    case CAMERA_TYPE.ADAS: {
                        device_info.incrementReceivedPackageCnt(data_len);
                        break;
                    }
                    case CAMERA_TYPE.DSM: {
                        device_info.incrementReceivedPackageCnt(data_len);
                        break;
                    }
                }
                dbg.log("Package: " + device_info.getReceivedPackageCnt() + " / " + device_info.getTotalPackages());
                device_info.addToBuffer(raw_file);
                let rx_pkg_cnt = device_info.getReceivedPackageCnt();
                progress_bar.update(rx_pkg_cnt);
                // Save for calculating next packet's CRC
                device_info.setLastCRC(actual_crc);
            }

            if (device_info.getTotalPackages() == device_info.getReceivedPackageCnt()) {
                current_state = FSM_STATE.FINISH_RECEIVING;
            }
            break;
        }

        case CMD_ID.METADATA: {
            /* Read data length minus CRC */
            let data_len = data_buffer.readUInt16BE(2);
            /* Get raw file data */
            let raw_data = data_buffer.slice(4, 4 + data_len);

            metadata.parseData(metadata, device_info, raw_data);
            dbg.log("[METADATA]: [" + raw_data.toString('hex') + "]");
            dbg.print("Got metadata:\n\n" + metadata.getString(device_info.getCameraType()));

            if (metadata_option == METADATA_TYPE.AT_START) {
                if (device_info.getCameraType() == CAMERA_TYPE.DUALCAM) {
                    current_state = FSM_STATE.SEND_FILEPATH;
                }
            }
            break;
        }

        case CMD_ID.FILEPATH: {
            let path = ParseFilePath(data_buffer);
            if (path.search("mdas9") > -1) {
                device_info.setCameraType(CAMERA_TYPE.ADAS);
            }
            if (path.search("dsm") > -1) {
                device_info.setCameraType(CAMERA_TYPE.DSM)
            }

            dbg.logAndPrint("Got file path: " + path);

            if (path.search("picture") > -1) {
                device_info.setExtension(".jpg");
            }
            if (path.search("video") > -1) {
                device_info.setExtension(".mp4");
            }
            device_info.setFileToDL(path);
            device_info.clearBuffer();
            device_info.setLastCRC(0);
            let query = Buffer.concat([Buffer.from([0, 8, 0, path.length]), Buffer.from(path)]);
            dbg.log('[TX]: [' + query.toString('hex') + ']');
            connection.write(query);
            current_state = FSM_STATE.WAIT_FOR_CMD;
            break;
        }
    }

    let camera_direction = 'video_rear';
    if (current_state == FSM_STATE.INIT) {
        //Create dir with device IMEI if it doesn't exist
        if (!fs.existsSync(media_folder)) {
            fs.mkdirSync(media_folder);
        }
        let imei = data_buffer.readBigUInt64BE(4);
        device_info.setDeviceDirectory(media_folder + '/' + imei.toString());
        if (!fs.existsSync(device_info.getDeviceDirectory())) {
            dbg.logAndPrint("Creating directory " + device_info.getDeviceDirectory());
            fs.mkdirSync(device_info.getDeviceDirectory());
        }
        // Read option byte to see what files are pending
        const option_byte = data_buffer.readUInt8(12);
        dbg.logAndPrint("Option byte: " + (option_byte >>> 0).toString(2));
        if ((camera_option == CAMERA_TYPE.ADAS) || (camera_option == CAMERA_TYPE.DSM) || (camera_option == CAMERA_TYPE.AUTO)) {
            if (option_byte & 0x02) {
                dbg.logAndPrint("File available! Sending file path request.");
                const query = Buffer.from([0, 12, 0, 2, 0, 0]);
                dbg.log('[TX]: [' + query.toString('hex') + ']');
                connection.write(query);
                current_state = FSM_STATE.WAIT_FOR_CMD;
                file_available = true;
            }
        }
        if ((camera_option == CAMERA_TYPE.DUALCAM || camera_option == CAMERA_TYPE.AUTO) && file_available == false) {
            if (option_byte & 0x20) {
                dbg.logAndPrint("DualCam rear video available!");
                device_info.setFileToDL(DUALCAM_FILE_PATH.DUALCAM_VIDEO_REAR);
                device_info.setExtension(".h265");
                device_info.setCameraType(CAMERA_TYPE.DUALCAM);
                file_available = true;
            } else if (option_byte & 0x10) {
                dbg.logAndPrint("DualCam front video available!");
                device_info.setFileToDL(DUALCAM_FILE_PATH.DUALCAM_VIDEO_FRONT);
                device_info.setExtension(".h265");
                device_info.setCameraType(CAMERA_TYPE.DUALCAM)
                file_available = true;
                camera_direction = 'video_front';
            } else if (option_byte & 0x08) {
                dbg.logAndPrint("DualCam rear photo available!");
                device_info.setFileToDL(DUALCAM_FILE_PATH.DUALCAM_PHOTO_REAR);
                device_info.setExtension(".jpeg");
                device_info.setCameraType(CAMERA_TYPE.DUALCAM)
                file_available = true;
                camera_direction = 'photo_rear';
            } else if (option_byte & 0x04) {
                dbg.logAndPrint("DualCam front photo available!");
                device_info.setFileToDL(DUALCAM_FILE_PATH.DUALCAM_PHOTO_FRONT);
                device_info.setExtension(".jpeg");
                device_info.setCameraType(CAMERA_TYPE.DUALCAM)
                file_available = true;
                camera_direction = 'photo_front';
            }
            if (file_available == true) {
                dbg.logAndPrint("Got DualCam file path.");
                device_info.clearBuffer();
                device_info.setLastCRC(0);
            }
        }
        if (metadata_option == METADATA_TYPE.AT_START) {
            current_state = FSM_STATE.SEND_METADATA_REQUEST;
        }
        if (metadata_option == METADATA_TYPE.NO_METADATA) {
            current_state = FSM_STATE.SEND_FILEPATH;
        }
        if (file_available == false) {
            device_info.setFileToDL(0);
            dbg.logAndPrint("No files available!");
            current_state = FSM_STATE.SEND_END;
        } else {
            let filename = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '').replace(/:/g, '').replace(/ /g, '');
            device_info.setCurrentFilename(filename);
            dbg.logAndPrint("Filename: " + device_info.getCurrentFilename());
        }
    }
            
    if (current_state == FSM_STATE.FINISH_RECEIVING) {
        progress_bar.stop();
        temp_file_buff = Buffer.alloc(0);
        temp_file_buff = Buffer.concat([temp_file_buff, device_info.getFileBuffer()]);
        let is_root_dir_in_file = device_info.getDeviceDirectory().indexOf('/') === 0;
        let root_exec_file = is_root_dir_in_file ? "." : "./";
        dbg.logAndPrint(`is_root_dir_in_file: [[${is_root_dir_in_file}]]`)
        const extra_name = `_${camera_direction}`;
        let file_buffer = root_exec_file + device_info.getDeviceDirectory() + '/' + device_info.getCurrentFilename() + extra_name + device_info.getExtension();
        fs.appendFile(file_buffer, temp_file_buff, function (err) {
            temp_file_buff = Buffer.alloc(0);
            if (err){
                return dbg.error(err, 'file_buffer: [[', file_buffer, ']]');
            } else {
                dbg.logAndPrint("Data written to file " + device_info.getCurrentFilename() + " successfully");
            }
        });

        if (device_info.getCameraType() == CAMERA_TYPE.DUALCAM) {
            if (device_info.getFileToDL().search("video") > -1) {
                ConvertVideoFile(device_info.getDeviceDirectory(), device_info.getCurrentFilename() + extra_name, device_info.getExtension(), metadata, metadata_option);
            }
        }

        if (metadata_option == METADATA_TYPE.AT_START) {
            fs.appendFile(root_exec_file + device_info.getDeviceDirectory() + '/' + device_info.getCurrentFilename() + ".txt", metadata.getString(device_info.getCameraType()), function (err) {
                temp_file_buff = Buffer.alloc(0);
                if (err) return dbg.error(err);
                dbg.logAndPrint("Metadata written to file " + device_info.getCurrentFilename() + " successfully");
            });
        }

        device_info.resetReceivedPackageCnt();
        device_info.clearBuffer();

        current_state = FSM_STATE.LOOK_FOR_FILES;
    }

    if (current_state == FSM_STATE.SEND_FILEPATH) {
        dbg.logAndPrint("Requesting file...");
        device_info.clearBuffer();
        device_info.setLastCRC(0);
        const query = Buffer.from([0, 8, 0, 7, 0, 0, 0, 0, 0, 0, 0]);
        query.write(device_info.getFileToDL(), 4);
        dbg.log('[TX]: [' + query.toString('hex') + ']');
        connection.write(query);
        current_state = FSM_STATE.WAIT_FOR_CMD;
    }

    if (current_state == FSM_STATE.REPEAT_PACKET) {
        dbg.logAndPrint("Requesting for a repeat of last packet...");
        sync_received = false;
        let offset = device_info.getReceivedPackageCnt();
        let query = Buffer.from([0, 2, 0, 4, 0, 0, 0, 0]);
        if (device_info.getCameraType() == CAMERA_TYPE.DUALCAM) {
            query.writeUInt32BE(offset + 1, 4);
        }
        if (device_info.getCameraType() == CAMERA_TYPE.ADAS) {
            query.writeUInt32BE(offset, 4);
        }
        if (device_info.getCameraType() == CAMERA_TYPE.DSM) {
            query.writeUInt32BE(offset, 4);
        }
        dbg.log('[TX]: [' + query.toString('hex') + ']');
        connection.write(query);
        current_state = FSM_STATE.WAIT_FOR_CMD;
    }

    if (current_state == FSM_STATE.SEND_METADATA_REQUEST) {
        dbg.logAndPrint("Requesting metadata...");
        let query = 0;
        if (device_info.getCameraType() == CAMERA_TYPE.DUALCAM) {
            query = Buffer.from([0, 10, 0, 7, 0, 0, 0, 0, 0, 0, 0]);
            query.write(device_info.getFileToDL(), 4);
        } else {
            query = Buffer.from([0, 10, 0, 0]);
        }
        dbg.log('[TX]: [' + query.toString('hex') + ']');
        connection.write(query);
        current_state = FSM_STATE.WAIT_FOR_CMD;
    }

    if (current_state == FSM_STATE.SEND_COMPLETE) {
        dbg.logAndPrint("Completing upload");
        // Close session
        const query = Buffer.from([0, 5, 0, 4, 0, 0, 0, 0]);
        dbg.log('[TX]: [' + query.toString('hex') + ']');
        connection.write(query);

        device_info.setTotalPackages(0);
        device_info.resetReceivedPackageCnt();
        device_info.setLastCRC(0);
        device_info.setCameraType(CAMERA_TYPE.NONE);

        current_state = FSM_STATE.END;
    }

    if (current_state == FSM_STATE.LOOK_FOR_FILES) {
        dbg.logAndPrint("Looking for more files...");
        const query = Buffer.from([0, 9]);
        dbg.log('[TX]: [' + query.toString('hex') + ']');
        connection.write(query);
        current_state = FSM_STATE.INIT;
    }

    if (current_state == FSM_STATE.SEND_END) {
        dbg.logAndPrint("Closing session");
        const query = Buffer.from([0, 0, 0, 0]);
        dbg.log('[TX]: [' + query.toString('hex') + ']');
        connection.write(query);
        current_state = FSM_STATE.END;
    }

    return current_state;
}