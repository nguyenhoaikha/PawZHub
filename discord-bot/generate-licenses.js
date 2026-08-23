// Generate License Codes for PawZHub
// Usage: node generate-licenses.js <count>

const mongoose = require('mongoose');
require('dotenv').config();

const licenseSchema = new mongoose.Schema({
    code: { type: String, required: true, unique: true },
    status: { type: String, enum: ['unused', 'redeemed'], default: 'unused' },
    redeemedBy: { type: String, default: null },
    redeemedAt: { type: Date, default: null },
    redeemedUsername: { type: String, default: null },
    generatedKey: { type: String, default: null },
    createdAt: { type: Date, default: Date.now },
    batchId: { type: String, default: null }
});

const License = mongoose.model('License', licenseSchema);

// Generate random 8-char hex code
function generateLicenseCode() {
    const chars = '0123456789abcdef';
    let code = '';
    for (let i = 0; i < 8; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
}

// Generate batch ID
function generateBatchId() {
    const date = new Date();
    return `BATCH-${date.getFullYear()}${(date.getMonth()+1).toString().padStart(2,'0')}${date.getDate().toString().padStart(2,'0')}-${Date.now().toString().slice(-4)}`;
}

async function generateLicenses(count) {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/pawzhub');
        console.log('✅ Connected!\n');
        
        const batchId = generateBatchId();
        console.log(`📦 Batch ID: ${batchId}`);
        console.log(`🔑 Generating ${count} license codes...\n`);
        console.log('─'.repeat(50));
        
        const licenses = [];
        
        for (let i = 0; i < count; i++) {
            let code = generateLicenseCode();
            
            // Ensure unique
            let exists = await License.findOne({ code: code });
            while (exists) {
                code = generateLicenseCode();
                exists = await License.findOne({ code: code });
            }
            
            // Create license
            const license = await License.create({ 
                code: code,
                batchId: batchId
            });
            
            licenses.push(code);
            console.log(`${(i+1).toString().padStart(3, ' ')}. ${code}`);
        }
        
        console.log('─'.repeat(50));
        console.log(`\n✅ Generated ${count} licenses successfully!`);
        console.log(`📊 Batch ID: ${batchId}`);
        
        // Export to file
        const fs = require('fs');
        const filename = `licenses-${batchId}.txt`;
        fs.writeFileSync(filename, licenses.join('\n'));
        console.log(`💾 Saved to: ${filename}\n`);
        
        process.exit(0);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

// Get count from command line
const count = parseInt(process.argv[2]) || 10;

if (count < 1 || count > 1000) {
    console.error('❌ Count must be between 1 and 1000');
    process.exit(1);
}

generateLicenses(count);
