const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkRevenueCatConfig() {
  try {
    const doc = await db.collection('AppInfo').doc('revenue_cat').get();
    
    if (!doc.exists) {
      console.log('❌ Documento AppInfo/revenue_cat não existe!');
      return;
    }
    
    const data = doc.data();
    console.log('✅ Documento revenue_cat encontrado:');
    console.log(JSON.stringify(data, null, 2));
    
    console.log('\n📋 Verificação específica:');
    console.log('  - android_public_api_key:', data.android_public_api_key ? '✅ ' + data.android_public_api_key.substring(0, 20) + '...' : '❌ não encontrada');
    console.log('  - ios_public_api_key:', data.ios_public_api_key ? '✅ ' + data.ios_public_api_key.substring(0, 20) + '...' : '❌ não encontrada');
    console.log('  - REVENUE_CAT_ENTITLEMENT_ID:', data.REVENUE_CAT_ENTITLEMENT_ID || '❌ null');
    console.log('  - REVENUE_CAT_OFFERINGS_ID:', data.REVENUE_CAT_OFFERINGS_ID || '❌ null');
    
  } catch (error) {
    console.error('❌ Erro:', error);
  }
  
  process.exit(0);
}

checkRevenueCatConfig();
