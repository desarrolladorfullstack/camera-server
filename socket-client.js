const net = require('net');
/* const readline = require('readline-sync') */

const options = {
    port: 9098,
    host: '192.168.20.109'
}

const client = net.createConnection(options)

client.on('connect', ()=>{
    console.log('Conexión satisfactoria!!')
    /* sendLine() */
    sendTest();
})

client.on('data', (data)=>{
    console.log('El servidor dice:' ,  data)
    /* sendLine() */
})

client.on('error', (err)=>{
    console.log(err.message)
})

/* function sendLine() {
    var line = readline.question('\ndigite alguna cosa\t')
    if (line == "0") {
        client.end()
    }else{
        client.write(line)
    }
} */
function sendTest(){
    client.write(Buffer.from('000f383630383936303530373934383538', 'hex'));
}