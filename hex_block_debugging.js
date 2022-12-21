const fs_mod = require('fs')
const crc_mod = require('./crc_calc')
const file_path = 'C:\\Projects\\Node\\media\\file_raw_1663338720827_00030efafb4bd16a5c000400_photof'
let block_erase = []
let init_crc = 0
fs_mod.readFile(file_path, (err,data)=>{
    const block_length = data.length
    let block_offset = 0
    while (block_offset < block_length){
        let block_offset_loop = block_offset
        let block_extract = data.subarray(block_offset,block_offset+1024)
        /* console.log(block_extract.subarray(0, 64), block_length) */
        let repeated = 0
        if (block_erase.includes(block_offset)){
            console.log(console.log('Omitir:', block_offset))
            block_offset_loop = 0
            block_offset+=1024
            continue
        }
        if ((block_offset / 1024) > 10){
            break
        }
        console.log(typeof init_crc, (init_crc).toString(16))
        init_crc = crc_mod.calculate_crc(init_crc, block_extract)
        console.log((block_extract.subarray(0, 32)).toString('hex'), 'crc', block_offset, init_crc, (init_crc).toString(16))
        while (block_offset_loop < block_length){
            /* if (block_offset_loop > (2035*1024)) break */
            block_offset_loop+=1024
            const block_part = data.subarray(block_offset_loop,block_offset_loop+1024)
            const offset_repeated = block_part.indexOf(block_extract.subarray(0, 64))
            if (offset_repeated == 0){
                if (repeated == 0){
                    console.log("*********************",block_offset,"*********************")
                }
                repeated ++
                console.log('Repetido:', block_extract.subarray(0, 64).toString('hex'),
                block_offset_loop, (block_offset_loop - block_offset)/1024 , offset_repeated)
                block_erase.push(block_offset_loop)
            } 
        } 
        if (repeated > 0){
            console.log(">>>", repeated)
        }
        write(file_path+'_fixed', block_extract)
        block_offset_loop = 0
        block_offset+=1024
    }
})
function write(file_path, packet_data) {
    fs_mod.appendFileSync(
        file_path,
        packet_data,
        (err) => handled_error_fs(err))
}