import makeWASocket, {
    useMultiFileAuthState,
    DisconnectReason,
    fetchLatestBaileysVersion,
} from '@whiskeysockets/baileys'
import { Boom } from '@hapi/boom'
import express from 'express'
import qrcode from 'qrcode-terminal'
import pino from 'pino'
import 'dotenv/config'

const app = express()
app.use(express.json())

const PORT = process.env.PORT || 3001
const SECRET = process.env.SECRET_KEY || 'changeme'

let sock = null
let isConnected = false

async function connectToWA() {
    const { state, saveCreds } = await useMultiFileAuthState('./auth_state')
    const { version } = await fetchLatestBaileysVersion()

    sock = makeWASocket({
        version,
        auth: state,
        logger: pino({ level: 'silent' }),
        printQRInTerminal: false,
    })

    sock.ev.on('creds.update', saveCreds)

    sock.ev.on('connection.update', ({ connection, lastDisconnect, qr }) => {
        if (qr) {
            console.log('\n📱 Scan QR ini untuk menghubungkan WhatsApp:\n')
            qrcode.generate(qr, { small: true })
        }

        if (connection === 'close') {
            isConnected = false
            const statusCode = new Boom(lastDisconnect?.error)?.output?.statusCode
            const shouldReconnect = statusCode !== DisconnectReason.loggedOut

            if (shouldReconnect) {
                console.log('Koneksi terputus, reconnecting...')
                connectToWA()
            } else {
                console.log('Logged out. Hapus folder auth_state/ lalu restart.')
            }
        }

        if (connection === 'open') {
            isConnected = true
            console.log('✅ WhatsApp berhasil terhubung.')
        }
    })
}

function requireSecret(req, res, next) {
    if (req.headers['x-secret-key'] !== SECRET) {
        return res.status(401).json({ error: 'Unauthorized' })
    }
    next()
}

function normalizeJid(phone) {
    // "+6281234567890" → "6281234567890@s.whatsapp.net"
    return phone.replace(/^\+/, '').replace(/\D/g, '') + '@s.whatsapp.net'
}

app.get('/status', (req, res) => {
    res.json({ connected: isConnected })
})

app.post('/send', requireSecret, async (req, res) => {
    const { phone, message } = req.body

    if (!phone || !message) {
        return res.status(400).json({ error: 'phone dan message wajib diisi.' })
    }

    if (!isConnected || !sock) {
        return res.status(503).json({ error: 'WhatsApp belum terhubung.' })
    }

    try {
        const jid = normalizeJid(phone)
        await sock.sendMessage(jid, { text: message })
        res.json({ success: true })
    } catch (err) {
        console.error('Gagal kirim pesan:', err?.message)
        res.status(500).json({ error: 'Gagal mengirim pesan.' })
    }
})

connectToWA()

app.listen(PORT, () => {
    console.log(`WA Service berjalan di port ${PORT}`)
})
