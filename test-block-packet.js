const fs_mod = require('fs')
let block = []
block.push('462060d52d3a512c0ae782455f5c551894b584592cd89eaa720d62c4338ad5d718a5a80a7049e2b016ebc98e667fe0567fc85265a29e8a7cdb8d46e07492e0807d978ad43599e1b429a4404fde705cfd49cff5ad4a96522196357186008a83cb40c028c015625c8538e4d4712f193d6a4a1c2a1b985678991c707f4ab1814606280392b9b716a922b29dc5b93ea29d647231fc3eb5bf7f682ea1007de1d2b2843f675d98e0d21b2199704e39c54b115084d579250370f5a624b8047634750e83dce49e79aa6486900f4ab123ed43b40c919aaf6cacc7a726988b5918e3815138dca769c03c93575ece4106f6181516ccab2e060f140d1889b64d42341c2e7915a3a9c68d6fb7b92314f4b448df78fbd44e15e3e7820d0089506100153a1db137a9a02aec1eb51c8db78a4b613dc89c5466a42c3bd46e78a62206383d6a4b7932e0138c739a8d88a67f09f7a607ffd9')

let recent_packet = undefined
for (let line of block) { 
    const packet_hex = line.substring(8, line.length - 4)
    if (packet_hex == recent_packet){
        continue
    }
    const isCreated = recent_packet != undefined
    if (!isCreated){
        fs_mod.writeFileSync('example.jpg',
     Buffer.from(packet_hex, 'hex'),
      'utf8', 
      (error) => { if (error) console.error('error', error) })
    }else{
        fs_mod.appendFileSync('example.jpg',
     Buffer.from(packet_hex, 'hex'),
      'utf8', 
      (error) => { if (error) console.error('error', error) })
    }
    recent_packet = packet_hex  
}