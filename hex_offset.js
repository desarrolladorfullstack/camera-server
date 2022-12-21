const packet_offset = 548
let payload_hex = ['00', '00', '00', packet_offset]
if (packet_offset > 255){
    let hex_offset = packet_offset.toString(16)
    if (hex_offset.length%2 == 1 ) { hex_offset = "0"+hex_offset}
    console.log('hex', hex_offset)
    for (let count = 0; count < Math.round(hex_offset.length/2) ; count ++) {
        const start = hex_offset.length - (count * 2) - 2
        const end = hex_offset.length - (count * 2)
        const offset_byte = hex_offset.substring(start, end)
        console.log('offset', offset_byte , count, start, end)
        payload_hex[payload_hex.length-1-count]=offset_byte
    }
}
console.log(payload_hex, Buffer.from(payload_hex.join(''),'hex'))